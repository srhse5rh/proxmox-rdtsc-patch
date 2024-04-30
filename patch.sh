#!/bin/bash

echo '
/* EDITED BY PATCH */
static u32 print_once = 1;
static int handle_rdtsc(struct kvm_vcpu *vcpu)
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
			u64 fake_diff =  diff / 16; // if you have 3.2Ghz on your vm, change 20 to 16
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
static int handle_rdtscp(struct kvm_vcpu *vcpu)
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
			u64 fake_diff =  diff / 16; // if you have 3.2Ghz on your vm, change 20 to 16
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

static int handle_umwait(struct kvm_vcpu *vcpu)
{
	svm_skip_emulated_instruction(vcpu);
	return 1;
}

static int handle_tpause(struct kvm_vcpu *vcpu)
{
	svm_skip_emulated_instruction(vcpu);
	return 1;
}
/* EDITED BY PATCH */
' >svm-patch-1

echo '
	/* EDITED BY PATCH */
	svm_set_intercept(svm, INTERCEPT_RDTSC);
	svm_set_intercept(svm, INTERCEPT_RDSCP);
	svm_set_intercept(svm, INTERCEPT_UMWAIT);
	svm_set_intercept(svm, INTERCEPT_TPAUSE);
	/* EDITED BY PATCH */
' >svm-patch-2

echo '
	/* EDITED BY PATCH */
	[EXIT_REASON_RDTSC]			= handle_rdtsc,
	[EXIT_REASON_RDTSCP]			= handle_rdtscp,
	[EXIT_REASON_UMWAIT]			= handle_umwait,
	[EXIT_REASON_TPAUSE]			= handle_tpause,
	/* EDITED BY PATCH */
' >svm-patch-3

svmfile="submodules/ubuntu-kernel/arch/x86/kvm/svm/svm.c"

sed -i -e '/const svm_exit_handlers/r svm-patch-1' -e //N ${svmfile}

sed -i '/svm_set_intercept(svm, INTERCEPT_RSM)/r svm-patch-2' ${svmfile}

sed -i '/SVM_EXIT_VMGEXIT/r svm-patch-3' ${svmfile}
