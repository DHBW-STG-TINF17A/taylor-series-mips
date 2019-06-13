################################################################################################################################
#
#   TAYLOR SERIES EXPANSION IN MIPS ASSEMBLY                            Corporate State University Baden-Wuerttemberg, Stuttgart
#   by Stefan Goldschmidt                                                                              Computer Science, TINF17A
#   and Oliver Rudzinski                                                      Computer Architecture, Prof. Dr.-Ing. Alfred Strey
#
################################################################################################################################

.data
    # start prompts
    prompt_lower: .asciiz "Enter a lower bound: "
    prompt_upper: .asciiz "Enter an upper bound: "
    prompt_size:  .asciiz "Enter a step size: "
    
    # end prompts
    end_prompt:   .asciiz "Would you like to run another calculation? (0: No, 1: Yes) "
    goodbye:      .asciiz "Thank you. Have a nice day. :-)"
    
    # warnings and errors
    bound_error:  .asciiz "You have entered a lower bound which was larger than the upper bound. \n"
    step_size_wrn:.asciiz "A step size lower than 0.1 is not recommended due to the lack of required precision with floats. Would you like to continue or re-enter your inputs? (0: Continue, 1: Re-enter) " 

    # interface assets
    lines:        .asciiz "--------------------------------------------------------------------------------\n"
    new_line:     .asciiz "\n"
    tab:          .asciiz "\t\t\t"
    header:       .asciiz "x\t\t\te^x\t\t\tln(x)\n"
    
    # constants
    fl_minus_one: .float -1.0
    int_minus_one:.word -1
    fl_two:       .float 2.0
    fl_ln2:       .float 0.6931464

    # bounds
    exp_lower_bound: .float -8.1
    exp_upper_bound: .float 8.1
    ln_lower_bound: .float 0.0
    precision:      .float 0.1

.align 2

.text
.globl main
.ent main

main:
    # lower bound   in $f17
    # upper bound   in $f18
    # step size     in $f19

    # ask user for lower bound input
    la $a0, prompt_lower
    li $v0, 4
    syscall

    li $v0, 6
    syscall

    # save value to register
    mov.s $f17, $f0

    # ask user for upper bound input
    la $a0, prompt_upper
    li $v0, 4
    syscall

    li $v0, 6
    syscall

    # save value to register
    mov.s $f18, $f0

    # check for lower bound <= upper bound
    c.le.s $f17, $f18
    bc1f wrong_input

    # ask user for step size input
    la $a0, prompt_size
    li $v0, 4
    syscall

    li $v0, 6
    syscall

    # save value to register
    mov.s $f19, $f0

    # check for step size lower than 0.1
    l.s $f20, precision
    c.lt.s $f19, $f20
    bc1t prec_warning

    # user interface preperation
    prepare_main:
        # print spacing lines
        la $a0, lines
        li $v0, 4
        syscall

        # print header
        la $a0, header
        li $v0, 4
        syscall

        # print spacing lines
        la $a0, lines
        li $v0, 4
        syscall

    # loop for printing the requested values
    loop_main:
        # leave loop if lower bound register value is not less than or equal the upper bound value
        c.lt.s $f17, $f18
        bc1f ret_main

        # print current lower bound to the screen
        mov.s $f12, $f17
        li $v0, 2
        syscall

        # print tab seperator
        la $a0, tab
        li $v0, 4
        syscall

        # load current lower bound value into argument register
        mov.s $f0, $f17

        # calculate exp
        jal exp

        # print exp of current value to the console
        li $v0, 2
        syscall

        # print tab seperator
        la $a0, tab
        li $v0, 4
        syscall

        # reload current lower bound value into argument register
        mov.s $f0, $f17

        # uncomment line 147 for ln(exp(x))
        ################################
        # mov.s $f0, $f12
        ################################

        # calculate ln
        jal ln

        # print ln of current value to the console
        li $v0, 2
        syscall

        # increment lower bound value by one step size
        add.s $f17, $f17, $f19

        la $a0, new_line
        li $v0, 4
        syscall

        j loop_main
    
    # notify user about incorrect input regarding the bounds
    wrong_input:
        # print error message
        la $a0, bound_error
        li $v0, 4
        syscall

        j main

    # notify user about potential accuracy lost when choosing step sizes below 0.1
    prec_warning:
        la $a0, step_size_wrn
        li $v0, 4
        syscall

        li $v0, 5
        syscall

        # if 1, repeat program, if 0, continue
        bne $v0, $zero, main
        j prepare_main

    ret_main:
        # print spacing lines
        la $a0, lines
        li $v0, 4
        syscall
        
        # print end message
        la $a0, end_prompt
        li $v0, 4
        syscall

        # read user input
        li $v0, 5
        syscall
        # if 1, repeat program, if 0, end program
        bne $v0, $zero, main

        la $a0, goodbye
        li $v0, 4
        syscall
        
        li $v0, 10
        syscall
.end main


exp:
    # argument x                in $f0
    # variable nom              in $f1
    # variable den              in $f2
    # loop variable i (int)     in $t0
    # loop condition variable   in $t1
    # return variable sum       in $f12
    # loop variable i (float)   in $f3
    # i-th summand              in $f4
    # lower bound               in $f29
    # upper bound               in $f30

    l.s $f29, exp_lower_bound
    l.s $f30, exp_upper_bound

    c.lt.s $f0, $f29
    bc1t exp_out_of_bounds
    
    c.le.s $f0, $f30
    bc1f exp_out_of_bounds

    # initialize nom and den with 1.0
    li.s    $f1, 1.0
    li.s    $f2, 1.0

    # set initial value for sum
    li.s    $f12, 1.0

    # set loop variables
    li      $t0, 1
    li      $t1, 20

    # loop to concatenate summands
    loop_exp:
        # leave loop if loop variable has become larger than loop condition variable
        bgt $t0, $t1, ret_exp

        # calculate new nominator: nom = nom * x
        mul.s $f1, $f1, $f0

        # calculate new denominator: den = den * i
        mtc1 $t0, $f3
        cvt.s.w $f3, $f3    # convert i into float
        mul.s $f2, $f2, $f3

        # calculate i-th summand
        div.s $f4, $f1, $f2

        # append i-th summand to the total sum
        add.s $f12, $f12, $f4

        # increment loop variable i
        addi $t0, $t0, 1

        j loop_exp
    
    # set error value if argument is out of bounds
    exp_out_of_bounds:
        li.s $f12, -1.0

    # exit point when end of loop is reached
    ret_exp:
        jr $ra
.end exp

ln0:
    # argument x            in $f0
    # variable nom          in $f1
    # variable den          in $f2
    # quotient nom / den    in $f3
    # i-th summand          in $f4
    # variable sign (float) in $f5
    # value (x - 1)         in $f6
    # constant -1.0         in $f13
    # variable sign         in $t0
    # constant -1           in $t1
    # loop variable i       in $t2
    # loop condition        in $t3
    # return variable sum   in $f12

    # initialize constants:
    li.s    $f13, -1.0
    li      $t1, -1

    # initialize nom with value x - 1.0
    add.s   $f1, $f0, $f13
    mov.s   $f6, $f1    # save value for later

    # initialize den with 1.0
    li.s    $f2, 1.0

    # initialize sign variable positively
    li      $t0, 1

    # make first summand returnable in case loop is not used
    mov.s    $f12, $f1
    
    # set loop variables
    li      $t2, 1
    li      $t3, 250

    # loop to concatenate summands
    loop_ln0:
        # leave loop if loop variable has become larger than loop condition variable
        bgt $t2, $t3, ret_ln0

        # calculate i-th nominator: nom = nom * (x - 1)
        mul.s $f1, $f1, $f6

        # calculate i-th denominator: den = den + 1
        sub.s $f2, $f2, $f13     # den + 1 == den - (-1)

        # invert sign variable
        mul $t0, $t0, $t1

        # calculate i-th (nom / den)
        div.s $f3, $f1, $f2

        # multiply (nom / den) with i-th sign -> determine i-th summand
        mtc1 $t0, $f5
        cvt.s.w $f5, $f5    # convert i-th sign integer to float
        mul.s $f4, $f3, $f5

        # append i-th summand to the total sum
        add.s $f12, $f12, $f4

        # increment loop variable
        addi $t2, $t2, 1

        j loop_ln0
    
    # exit point when end of loop is reached
    ret_ln0:
        jr $ra
.end ln0

ln:
    # argument x            in $f0
    # variable ln(x)        in $f1
    # variable b (float)    in $f2
    # constant 2.0          in $f3
    # constant ln(2)        in $f4
    # value b * ln(2)       in $f5
    # variable b (int)      in $t4
    # return variable sum   in $f12 (overwritten at the end)
    # lower bound           in $f31

    l.s     $f31, ln_lower_bound

    c.le.s $f0, $f31
    bc1t    ln_out_of_bounds

    # initialize constant values
    li.s    $f3, 2.0

    # initialize b with value 0
    li      $t4, 0

    # loop for splitting x into a * 2^b
    loop_ln:
        # leave loop if a has become less or equal the value of 2.0
        c.le.s $f0, $f3
        bc1t fin_ln

        # divide x by 2
        div.s $f0, $f0, $f3

        # increment b
        addi $t4, $t4, 1

        j loop_ln
    
    # exit point when end of loop is reached
    fin_ln:
        # calculate ln(x) (x* = x/2^n * 2^n)

        addi $sp, $sp, -4
        sw $ra, 0($sp)
        jal ln0
        
        # reinitialize constants
        li.s    $f3, 2.0
        li.s    $f4, 0.6931464

        # calculate product b * ln(2)
        mtc1 $t4, $f2
        cvt.s.w $f2, $f2    # convert interger variable b into float
        mul.s $f5, $f2, $f4

        # calculate final sum
        add.s $f12, $f12, $f5
        #     └─────│────────── return value of ln subroutine 
        #           └────────── return value of ln0 subroutine (overwritten)
        
        lw $ra, 0($sp)
        addi, $sp, $sp, 4 
        j ret_ln

    # set error value if argument is out of bounds
    ln_out_of_bounds:
        li.s $f12, -1.0

    # exit point when calculation of ln(x) is reached.    
    ret_ln:  
        jr $ra
.end ln
