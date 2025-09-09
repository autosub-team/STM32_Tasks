*** Settings ***
Resource            ${RENODEKEYWORDS}

Suite Setup         Setup
Suite Teardown      Teardown
Test Teardown       Test Teardown


*** Variables ***
${desired_freq}                 {{FRQ}}
${desired_duty_cycle}           {{DUTY}}
${desired_pin}                  {{PIN}}
${desired_tim_channel}          {{TIM_CHANNEL}}
${simulation_cycles}            {{SIMCYCLES}}
${percentage_tolerance}         1


*** Test Cases ***
Test for correct Implementation
    [Tags]    sels
    [Documentation]          Checks relevant Registers for correct values

    Create Nucleo Board

    Execute Command          pause
    Execute Command          emulation RunFor "5"

    ${GPIO_Clock_Enabled}=      Execute Command    sysbus.rcc ReadDoubleWord {{GPIO_clk_en_reg_offset}}
    Verify Register Value        ${GPIO_Clock_Enabled}    ${ {{GPIO_clk_en_bit_shift}} }    ${ {{GPIO_clk_en_mask}} }    ${ {{GPIO_clk_en_comp_val}} }    "GPIOx's clock is not enabled!"

    ${TIM_Clock_Enabled}=       Execute Command    sysbus.rcc ReadDoubleWord {{TIM_clk_en_reg_offset}}
    Verify Register Value        ${TIM_Clock_Enabled}    ${ {{TIM_clk_en_bit_shift}} }    ${ {{TIM_clk_en_mask}} }    ${ {{TIM_clk_en_comp_val}} }    "TIMx's clock is not enabled!"

    ${GPIO_mode}=               Execute Command    {{GPIO_PORT}} ReadDoubleWord {{GPIO_mode_reg_offset}}
    Verify Register Value        ${GPIO_mode}    ${ {{GPIO_mode_bit_shift}} }    ${ {{GPIO_mode_mask}} }    ${ {{GPIO_mode_comp_val}} }    "GPIOx PINy is not configured for Alternate Function!"
    
    ${GPIO_AF_fun}=             Execute Command    {{GPIO_PORT}} ReadDoubleWord {{GPIO_AF_reg_offset}}
    Verify Register Value        ${GPIO_AF_fun}    ${ {{GPIO_AF_bit_shift}} }    ${ {{GPIO_AF_mask}} }    ${ {{GPIO_AF_comp_val}} }    "GPIOA Pin is not configured with the correct Alternate Function!"

    ${TIM_Control1}=            Execute Command    sysbus.timer{{TIM}} ReadDoubleWord {{TIM_control1_reg_offset}}
    Verify Register Value        ${TIM_Control1}    ${ {{TIM_control1_bit_shift}} }    ${ {{TIM_control1_mask}} }    ${ {{TIM_control1_comp_val}} }    "Either counter not enabled or direction of counter is wrong!"

    ${TIM_Mode}=                Execute Command    sysbus.timer{{TIM}} ReadDoubleWord {{TIM_mode_reg_offset}}
    Verify Register Value        ${TIM_Mode}    ${ {{TIM_mode_bit_shift}} }    ${ {{TIM_mode_mask}} }    ${ {{TIM_mode_comp_val}} }    "Timer not configured in the correct mode!"

    ${TIM_OC_Pol_Enabled}=      Execute Command    sysbus.timer{{TIM}} ReadDoubleWord {{TIM_OC_pol_en_reg_offset}}
    Verify Register Value        ${TIM_OC_Pol_Enabled}    ${ {{TIM_OC_pol_en_bit_shift}} }   ${ {{TIM_OC_pol_en_mask}} }    ${ {{TIM_OC_pol_en_comp_val}} }    "OC not enabled/wrong polarity!"


Test for correct Frequency
    [Tags]    sels
    [Documentation]    Verifies correct frequency via timer base frequency (64MHz), prescaler and auto-reload register value
    
    Create Nucleo Board
    Execute Command          pause
    Execute Command          emulation RunFor "5"

    ${prescaler}=    Execute Command    sysbus.timer{{TIM}} ReadDoubleWord {{PRESCALER_reg_offset}}
    ${prescaler}=    Convert to Integer    ${prescaler}
    ${auto_reload}=    Execute Command    sysbus.timer{{TIM}} ReadDoubleWord {{ARR_reg_offset}}
    ${auto_reload}=    Convert to Integer    ${auto_reload}
    ${actual_frequency}=    Evaluate    ${64000000} / (${prescaler} + 1) / (${auto_reload} + 1)
    ${expected_frequency}=     Convert to Number    ${desired_freq}
    Should Be Equal Within Range    ${expected_frequency}  ${actual_frequency}  ${0.1}  "Wrong Timer Frequency. Expected: ${expected_frequency} vs Acutal: ${actual_frequency}"


Test for correct Duty Cycle
    [Tags]    sels
    [Documentation]    Verifies correct duty cycle via renode pwm-tester (=pt)
    
    Create Nucleo Board
    Execute Command          {{GPIO_PORT}}.pt Reset
    Execute Command          pause
    Execute Command          emulation RunFor "5"

    ${hp}=  Execute Command  {{GPIO_PORT}}.pt HighPercentage
    ${actual_percent}=    Convert Duty Cycle    ${hp}
    ${expected_percent}=    Convert to Integer    ${desired_duty_cycle}
    Should Be Equal Within Range    ${expected_percent}  ${actual_percent}  ${percentage_tolerance}  "Duty Cycle out of range. Expected: ${expected_percent} vs Acutal: ${actual_percent}"

    # ${ht}=  Execute Command  {{GPIO_PORT}}.pt HighTicks
    # ${hs}=  Ticks To Seconds  ${ht}

    # ${tim2_enabled}=  Execute Command  sysbus.timer2 Enabled
    # ${tim2_divider}=  Execute Command  sysbus.timer2 Divider
    # ${tim2_limit}=  Execute Command  sysbus.timer2 Limit
    # ${tim2_mode}=  Execute Command  {{GPIO_PORT}} ReadDoubleWord 0


*** Keywords ***
Create Nucleo Board
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_RCC.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_EXTI.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_UART.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_FlashController.cs

    Execute Command    $bin = @${CURDIR}/build/stm32-pwm_single_led.elf

    Execute Command    using sysbus
    Execute Command    mach create "STM32F334R8-Nucleo"
    Execute Command    machine LoadPlatformDescription @${CURDIR}/renode/renode_stm32f3/stm32f334R8_nucleo.repl

    Execute Command          machine LoadPlatformDescriptionFromString "pt: PWMTester @ {{GPIO_PORT}} {{GPIO_PIN}}"
    Execute Command          machine LoadPlatformDescriptionFromString "{{GPIO_PORT}}: { {{GPIO_PIN}} -> pt@0 }"
    # This line is needed to connect the CC channel to the correct pin.
    Execute Command          machine LoadPlatformDescriptionFromString "timer{{TIM}}: { {{CHANNEL}} -> {{GPIO_PORT}}@{{GPIO_PIN}} }"

    Execute Command    sysbus LoadELF $bin

Convert Duty Cycle
    [Arguments]              ${renode_duty_val}
    
    ${renode_duty_val}=  Remove String    ${renode_duty_val}    \n
    Should Not Be True           """${renode_duty_val}""" == """NaN"""  msg="Duty Cycle not available. Is pin connected?"
    #TODO(psv): decide if error message or set to 0
    #${hp}=  Run Keyword if   """${hp}""" == """NaN"""  Evaluate  int(0)
    ${num_var}=  Convert To Number  ${renode_duty_val}
    [Return]                 ${num_var}

Ticks To Seconds
    [Arguments]              ${ht}
    
    ${ht}=  Remove String    ${ht}    \n
    #${ht}=  Run Keyword if   """${ht}""" == """NaN"""  Evaluate  int(0)
    ${ht}=  Evaluate  int(${ht}) / (10**9)
    [Return]                 ${ht}

Should Be Equal Within Range
    [Arguments]              ${value0}  ${value1}  ${range}  ${msg}

    ${diff}=                 Evaluate  abs(${value0} - ${value1})

    Should Be True           ${diff} <= ${range}  msg=${msg}

Verify Register Value
    [Arguments]            ${renode_value}    ${bit_shift}    ${bit_mask}    ${compare_value}    ${err_msg}
    ${reg_value}=      Convert to Integer    ${renode_value}
    ${reg_shifted_masked}    Evaluate    (${reg_value}>>${bit_shift})&${bit_mask}
    Should Be Equal              ${reg_shifted_masked}    ${compare_value}    msg = ${err_msg}
