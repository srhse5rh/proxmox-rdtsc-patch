#!/bin/bash

echo '
/* EDITED BY PATCH */
static u32 print_once = 1;
static int handle_rdtsc_interception(struct kvm_vcpu *vcpu)
{
	static u64 rdtsc_fake = 0;
	static u64 rdtsc_prev = 0;
	u64 rdtsc_real = rdtsc();
	if(print_once)
	{
		printk("[handle_rdtsc] fake rdtsc svm function is working");
		print_once = 0;
		rdtsc_fake = rdtsc_real;
	}

	if(rdtsc_prev != 0)
	{
		if(rdtsc_real > rdtsc_prev)
		{
			u64 diff = rdtsc_real - rdtsc_prev;
			u64 fake_diff =  diff / 20; // if you have 3.2Ghz on your vm, change 20 to 16
			rdtsc_fake += fake_diff;
		}
	}
	if(rdtsc_fake > rdtsc_real)
	{
		rdtsc_fake = rdtsc_real;
	}
	rdtsc_prev = rdtsc_real;

	vcpu->arch.regs[VCPU_REGS_RAX] = rdtsc_fake & -1u;
	vcpu->arch.regs[VCPU_REGS_RDX] = (rdtsc_fake >> 32) & -1u;

	return svm_skip_emulated_instruction(vcpu);
}

static u32 print_once = 1;
static int handle_rdtscp_interception(struct kvm_vcpu *vcpu)
{
	static u64 rdtsc_fake = 0;
	static u64 rdtsc_prev = 0;
	u64 rdtsc_real = rdtsc();
	if(print_once)
	{
		printk("[handle_rdtsc] fake handle_rdtscp svm function is working");
		print_once = 0;
		rdtsc_fake = rdtsc_real;
	}

	if(rdtsc_prev != 0)
	{
		if(rdtsc_real > rdtsc_prev)
		{
			u64 diff = rdtsc_real - rdtsc_prev;
			u64 fake_diff =  diff / 20; // if you have 3.2Ghz on your vm, change 20 to 16
			rdtsc_fake += fake_diff;
		}
	}
	if(rdtsc_fake > rdtsc_real)
	{
		rdtsc_fake = rdtsc_real;
	}
	rdtsc_prev = rdtsc_real;

	vcpu->arch.regs[VCPU_REGS_RAX] = rdtsc_fake & -1u;
	vcpu->arch.regs[VCPU_REGS_RDX] = (rdtsc_fake >> 32) & -1u;

	return svm_skip_emulated_instruction(vcpu);
}

static int handle_umwait_interception(struct kvm_vcpu *vcpu)
{
	kvm_skip_emulated_instruction(vcpu);
	return 1;
}

static int handle_tpause_interception(struct kvm_vcpu *vcpu)
{
	kvm_skip_emulated_instruction(vcpu);
	return 1;
}
' >svm-patch-1

echo '
	/* EDITED BY PATCH */
	svm_set_intercept(svm, INTERCEPT_RDTSC);
	svm_set_intercept(svm, INTERCEPT_RDSCP);
	svm_set_intercept(svm, INTERCEPT_UMWAIT);
	svm_set_intercept(svm, INTERCEPT_TPAUSE);
' >svm-patch-2

echo '
	/* EDITED BY PATCH */
	[EXIT_REASON_RDTSC]			= handle_rdtsc_interception,
	[EXIT_REASON_RDTSCP]			= handle_rdtscp_interception,
	[EXIT_REASON_UMWAIT]			= handle_umwait_interception,
	[EXIT_REASON_TPAUSE]			= handle_tpause_interception,
' >svm-patch-3

svmfile="submodules/ubuntu-kernel/arch/x86/kvm/svm/svm.c"
vmxfile="submodules/ubuntu-kernel/arch/x86/kvm/vmx/vmx.c"

sed -i '/return kvm_handle_invpcid/{
    n
    n
    r svm-patch-1
}' ${svmfile}

sed -i '/svm_set_intercept(svm, INTERCEPT_RSM)/r svm-patch-2' ${svmfile}

sed -i '/SVM_EXIT_VMGEXIT/r svm-patch-3' ${svmfile}
