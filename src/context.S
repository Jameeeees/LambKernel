
	.globl   SaveContext
    .globl   LoadContext
     .p2align 2
	.type    SaveContext,%function
    .type    LoadContext,%function
    
// SP is the stack register a shortcut for typing r13. 
// LR is the link register a shortcut for r14. 
// And PC is the program counter a shortcut for typing r15.
//****************************************************************************
//  void SaveContext(void)
//***************************************************************************
SaveContext:      
//    stmdb SP!,{r0,r1,LR}
    // The ! means "Register write-back": 
    // the base register is used to calculate the address of the transfer, and is updated.
    // kind of like ! in Ruby
    stmdb SP!,{r0,r1}                   // Store SP - 8 = r0// SP - 4 = r1//

    //--savecontext--
    ldr r0,=Running	                    // Load address to context
    ldr r0,[r0]                         // Get the value in that address r0
    add r0,r0,#4                        // r0 += 4
    // STMIA = Store Multiple Increment After
    stmia r0,{r1-r12}	                // Save registers r1-r12
    nop
    nop
    nop    
    // Store return address, stands for the address of the next instruction in the context
    // LR = Link Register for return address
    mov r1,LR
    str r1,[r0,#52]                   // Save LR to TCB->PC, r0 has been added 4 before
          
    // mrs = Move to ARM register from system coprocessor register.
    mrs r1,CPSR                      // Load CPSR into r1
    str r1, [r0,#56]                 // and save to TCB->SPSR
    sub r0,r0,#4                     // Makes r0 point to context->r0
    ldr r1,[SP]                      // Loads r0 from stack
    str r1,[r0]		                 // Saves r0. 
         
    add r1,SP,#8                     // Fetch Stackpointer
    str r1,[r0,#52]                  // and save to TCB->SP  	  
    ldmia SP!,{r0,r1}                  	  
    mov PC,LR                        // Return to C-program
    
//****************************************************************************
//  void LoadContext(void)
//***************************************************************************    
LoadContext:

    ldr r0,=Running
    ldr r0,[r0]
		
    ldr r1, [r0,#52]                  // Catch Running-> SP
    sub SP,SP,#8	              // Find a unused stack area
    stmda SP!,{r1}                    // and put SP on the temporary stack 
    ldr r1,[r0,#4]                    // Fetch r0's value.TCB->context[1]
    stmda SP!,{r1}                    // push r1's value to stack       
    ldr r1,[r0]                       // Fetch r0's value.TCB->context[0]
    stmda SP!,{r1}                    // push r0's value to stack      
       
    add r0,r0,#4            
    ldmia r0!,{r1-r12}^               // Restore values for r1-r12          

    ldr r0,=Running
    ldr r0,[r0]    
    add r0,r0,#0x38            
    ldr r14,[r0]

    cmp r14,#0
    beq trap
    ldr r0,[r0,#8]                    // Load value for SPSR
    cmp r0,#0                         // If SPSR = 0, first loading.
    beq skipSPSR                      // then skip loading SPSR.
    msr CPSR_c,r0                     // else CPSR = TCB->SPSR
skipSPSR:          

    ldr r0,=Running
    ldr r0,[r0]    
    add r0,r0,#0x38            
    ldr r14,[r0]

    ldmib   SP!,{r0,r1}
    ldr SP,[r13,#4] 
    mov PC, r14                       // movs PC,r14, Branch to Running task
trap:
    b .

    