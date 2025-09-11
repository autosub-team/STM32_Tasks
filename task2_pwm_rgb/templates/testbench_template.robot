# Testbench for task2: pwm rgb -> since hardware is fixed, check implementation without randoms

*** Settings ***
Resource            ${RENODEKEYWORDS}

Suite Setup         Setup
Suite Teardown      Teardown
Test Teardown       Test Teardown


*** Variables ***
${desired_freq_tim3}                  {{FRQ_RED}}
${desired_freq_tim17}                 {{FRQ_GREEN}}
${desired_duty_cycle_tim3}            {{DUTY_RED}}
${desired_duty_cycle_tim17}           {{DUTY_GREEN}}
${simulation_cycles}                  {{SIMCYCLES}}
${percentage_tolerance}               1


*** Test Cases ***
Test for correct Implementation
    [Tags]    sels
    [Documentation]          Checks relevant Registers for correct values

    Create Nucleo Board

    Execute Command          pause
    Execute Command          emulation RunFor "5"

    ${GPIO_Clock_Enabled}=      Execute Command    sysbus.rcc ReadDoubleWord 20
    Verify Register Value        ${GPIO_Clock_Enabled}    ${17}    ${4}    ${4}    "GPIOA's or GPIOC's clock is not enabled!"

    ${TIM3_Clock_Enabled}=       Execute Command    sysbus.rcc ReadDoubleWord 28
    Verify Register Value        ${TIM3_Clock_Enabled}    ${1}    ${1}    ${1}    "TIM3's clock is not enabled!"

    ${TIM17_Clock_Enabled}=       Execute Command    sysbus.rcc ReadDoubleWord 24
    Verify Register Value        ${TIM17_Clock_Enabled}    ${18}    ${1}    ${1}    "TIM17's clock is not enabled!"

    ${GPIOA_mode}=               Execute Command    gpioPortA ReadDoubleWord 0
    Verify Register Value        ${GPIOA_mode}    ${14}    ${3}    ${2}    "At least one of the PINs is not configured for Alternate Function!"

    ${GPIOC_mode}=               Execute Command    gpioPortC ReadDoubleWord 0
    Verify Register Value        ${GPIOC_mode}    ${14}    ${3}    ${2}    "At least one of the PINs is not configured for Alternate Function!"
    
    ${GPIOA_AF_fun}=             Execute Command    gpioPortA ReadDoubleWord 32
    Verify Register Value        ${GPIOA_AF_fun}    ${28}    ${15}    ${1}    "GPIOA Pin7 is not configured with the correct Alternate Function!"
    
    ${GPIOC_AF_fun}=             Execute Command    gpioPortC ReadDoubleWord 32
    Verify Register Value        ${GPIOC_AF_fun}    ${28}    ${15}    ${2}    "GPIOC Pin7 is not configured with the correct Alternate Function!"

    ${TIM3_Control1}=            Execute Command    sysbus.timer3 ReadDoubleWord 0
    Verify Register Value        ${TIM3_Control1}    ${0}    ${17}    ${1}    "TIM3: Either counter not enabled or direction of counter is wrong!"

    ${TIM17_Control1}=            Execute Command    sysbus.timer17 ReadDoubleWord 0
    Verify Register Value        ${TIM17_Control1}    ${0}    ${1}    ${1}    "TIM17: Counter not enabled!"

    ${TIM3_Mode}=                Execute Command    sysbus.timer3 ReadDoubleWord 24
    Verify Register Value        ${TIM3_Mode}    ${12}    ${4103}    ${6}    "Timer 3 not configured in the correct mode!"
    
    ${TIM17_Mode}=                Execute Command    sysbus.timer17 ReadDoubleWord 24
    Verify Register Value        ${TIM17_Mode}    ${4}    ${4103}    ${6}    "Timer 17 not configured in the correct mode!"

    ${TIM3_OC_Pol_Enabled}=      Execute Command    sysbus.timer3 ReadDoubleWord 32
    Verify Register Value        ${TIM3_OC_Pol_Enabled}    ${4}   ${3}    ${1}    "TIM3: OC not enabled/wrong polarity!"

    ${TIM17_OC_Pol_Enabled}=      Execute Command    sysbus.timer17 ReadDoubleWord 32
    Verify Register Value        ${TIM17_OC_Pol_Enabled}    ${0}   ${3}    ${1}    "TIM17: OC not enabled/wrong polarity!"


Test for correct Frequency Timer 3
    [Tags]    sels
    [Documentation]    Verifies correct frequency via timer base frequency (64MHz), prescaler and auto-reload register value
    
    Create Nucleo Board
    Execute Command          pause
    Execute Command          emulation RunFor "5"

    ${prescaler}=    Execute Command    sysbus.timer3 ReadDoubleWord 40
    ${prescaler}=    Convert to Integer    ${prescaler}
    ${auto_reload}=    Execute Command    sysbus.timer3 ReadDoubleWord 44
    ${auto_reload}=    Convert to Integer    ${auto_reload}
    ${actual_frequency}=    Evaluate    ${64000000} / (${prescaler} + 1) / (${auto_reload} + 1)
    ${expected_frequency}=     Convert to Number    ${desired_freq_tim3}
    Should Be Equal Within Range    ${expected_frequency}  ${actual_frequency}  ${0.1}  "Wrong Timer 3 Frequency. Expected: ${expected_frequency} vs Acutal: ${actual_frequency}"


Test for correct Frequency Timer 17
    [Tags]    sels
    [Documentation]    Verifies correct frequency via timer base frequency (64MHz), prescaler and auto-reload register value
    
    Create Nucleo Board
    Execute Command          pause
    Execute Command          emulation RunFor "5"

    ${prescaler}=    Execute Command    sysbus.timer17 ReadDoubleWord 40
    ${prescaler}=    Convert to Integer    ${prescaler}
    ${auto_reload}=    Execute Command    sysbus.timer17 ReadDoubleWord 44
    ${auto_reload}=    Convert to Integer    ${auto_reload}
    ${actual_frequency}=    Evaluate    ${64000000} / (${prescaler} + 1) / (${auto_reload} + 1)
    ${expected_frequency}=     Convert to Number    ${desired_freq_tim17}
    Should Be Equal Within Range    ${expected_frequency}  ${actual_frequency}  ${0.1}  "Wrong Timer 17 Frequency. Expected: ${expected_frequency} vs Acutal: ${actual_frequency}"


Test for correct Duty Cycle Timer 3
    [Tags]    sels
    [Documentation]    Verifies correct duty cycle via renode pwm-tester (=pt)
    
    Create Nucleo Board
    Execute Command          gpioPortC.ptC Reset
    Execute Command          pause
    Execute Command          emulation RunFor "5"

    ${hp}=  Execute Command  gpioPortC.ptC HighPercentage
    ${actual_percent}=    Convert Duty Cycle    ${hp}
    ${expected_percent}=    Convert to Integer    ${desired_duty_cycle_tim3}
    Should Be Equal Within Range    ${expected_percent}  ${actual_percent}  ${percentage_tolerance}  "Duty Cycle timer 3 out of range. Expected: ${expected_percent} vs Acutal: ${actual_percent}"


Test for correct Duty Cycle Timer 17
    [Tags]    sels
    [Documentation]    Verifies correct duty cycle via renode pwm-tester (=pt)
    
    Create Nucleo Board
    Execute Command          gpioPortA.ptA Reset
    Execute Command          pause
    Execute Command          emulation RunFor "5"

    ${hp}=  Execute Command  gpioPortA.ptA HighPercentage
    ${actual_percent}=    Convert Duty Cycle    ${hp}
    ${expected_percent}=    Convert to Integer    ${desired_duty_cycle_tim17}
    Should Be Equal Within Range    ${expected_percent}  ${actual_percent}  ${percentage_tolerance}  "Duty Cycle timer 17 out of range. Expected: ${expected_percent} vs Acutal: ${actual_percent}"




*** Keywords ***
Create Nucleo Board
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_RCC.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_EXTI.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_UART.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_FlashController.cs

    Execute Command    $bin = @${CURDIR}/build/stm32-pwm_rgb.elf

    Execute Command    using sysbus
    Execute Command    mach create "STM32F334R8-Nucleo"
    Execute Command    machine LoadPlatformDescription @${CURDIR}/renode/renode_stm32f3/stm32f334R8_nucleo.repl

    Execute Command          machine LoadPlatformDescriptionFromString "ptA: PWMTester @ gpioPortA 7"
    Execute Command          machine LoadPlatformDescriptionFromString "gpioPortA: { 7 -> ptA@0 }"

    Execute Command          machine LoadPlatformDescriptionFromString "ptC: PWMTester @ gpioPortC 7"
    Execute Command          machine LoadPlatformDescriptionFromString "gpioPortC: { 7 -> ptC@0 }"
    # This line is needed to connect the CC channel to the correct pin.
    Execute Command          machine LoadPlatformDescriptionFromString "timer3: { 1 -> gpioPortC@7 }"
    Execute Command          machine LoadPlatformDescriptionFromString "timer17: { 0 -> gpioPortA@7 }"

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
