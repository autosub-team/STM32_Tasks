#!/usr/bin/env python3

########################################################################
# generateTestBench.py for STM32 task pwm
# Generates testvectors and fills a testbench for specified taskParameters
#
# Copyright (C) 2015 Martin  Mosbeck   <martin.mosbeck@gmx.at>
# License GPL V2 or later (see http://www.gnu.org/licenses/gpl2.txt)
########################################################################

import sys
import random

from jinja2 import FileSystemLoader, Environment


##################### Hardware Information ######################
# commented pins and timers are combinations not available (yet) in renode
hardware_dict = {"PA5": dict(),
                 "PA6": dict(),
                 "PA7": dict(),
                 #"PB6": dict(),
                 "PC7": dict(),
                 "TIM2_CH1": dict(),
                 "TIM3_CH1": dict(),
                 "TIM3_CH2": dict(),
                 "TIM16_CH1": dict(),
                 #"TIM16_CH1N": dict(),
                 "TIM17_CH1": dict()
                }

hardware_dict["PA5"].update({"GPIO_PORT": "gpioPortA",  # all values verified
                             "GPIO_PIN": "5",

                             "GPIO_clk_en_reg_offset": "20", 
                             "GPIO_clk_en_bit_shift": "17", "GPIO_clk_en_mask": "1", "GPIO_clk_en_comp_val": "1",

                             "GPIO_mode_reg_offset": "0",
                             "GPIO_mode_bit_shift": "10", "GPIO_mode_mask": "3", "GPIO_mode_comp_val": "2",

                            # AF is closer connected to timer/channel
                             })

hardware_dict["PA6"].update({"GPIO_PORT": "gpioPortA",  # all values verified
                             "GPIO_PIN": "6",

                             "GPIO_clk_en_reg_offset": "20", 
                             "GPIO_clk_en_bit_shift": "17", "GPIO_clk_en_mask": "1", "GPIO_clk_en_comp_val": "1",

                             "GPIO_mode_reg_offset": "0",
                             "GPIO_mode_bit_shift": "12", "GPIO_mode_mask": "3", "GPIO_mode_comp_val": "2",

                             })

hardware_dict["PA7"].update({"GPIO_PORT": "gpioPortA",  # all values verified
                             "GPIO_PIN": "7",

                             "GPIO_clk_en_reg_offset": "20", 
                             "GPIO_clk_en_bit_shift": "17", "GPIO_clk_en_mask": "1", "GPIO_clk_en_comp_val": "1",

                             "GPIO_mode_reg_offset": "0",
                             "GPIO_mode_bit_shift": "14", "GPIO_mode_mask": "3", "GPIO_mode_comp_val": "2",
                             })

# hardware_dict["PB6"].update({"GPIO_PORT": "gpioPortB",  # all values verified
#                              "GPIO_PIN": "6",

#                              "GPIO_clk_en_reg_offset": "20", 
#                              "GPIO_clk_en_bit_shift": "18", "GPIO_clk_en_mask": "1", "GPIO_clk_en_comp_val": "1",

#                              "GPIO_mode_reg_offset": "0",
#                              "GPIO_mode_bit_shift": "12", "GPIO_mode_mask": "3", "GPIO_mode_comp_val": "2",
#                              })

hardware_dict["PC7"].update({"GPIO_PORT": "gpioPortC",  # all values verified
                             "GPIO_PIN": "7",

                             "GPIO_clk_en_reg_offset": "20", 
                             "GPIO_clk_en_bit_shift": "19", "GPIO_clk_en_mask": "1", "GPIO_clk_en_comp_val": "1",

                             "GPIO_mode_reg_offset": "0",
                             "GPIO_mode_bit_shift": "14", "GPIO_mode_mask": "3", "GPIO_mode_comp_val": "2",

                             })

hardware_dict["TIM2_CH1"].update({"TIM": "2",   # all values verified
                                  "CHANNEL": "0",   # in renode, channel numbering starts at 0 -> CH1 = 0, CH2 = 1, ...

                                  "PRESCALER_reg_offset": "40",
                                  "ARR_reg_offset": "44",

                                  "TIM_clk_en_reg_offset": "28", 
                                  "TIM_clk_en_bit_shift": "0", "TIM_clk_en_mask": "1", "TIM_clk_en_comp_val": "1",

                                  "TIM_control1_reg_offset": "0",
                                  "TIM_control1_bit_shift": "0", "TIM_control1_mask": "17", "TIM_control1_comp_val": "1",

                                  "TIM_mode_reg_offset": "24",
                                  "TIM_mode_bit_shift": "4", "TIM_mode_mask": "4103", "TIM_mode_comp_val": "6",

                                  "TIM_OC_pol_en_reg_offset": "32",
                                  "TIM_OC_pol_en_bit_shift": "0", "TIM_OC_pol_en_mask": "3", "TIM_OC_pol_en_comp_val": "1",
                                    
                                  "GPIO_AF_reg_offset": "32",
                                  "GPIO_AF_bit_shift": "20", "GPIO_AF_mask": "15", "GPIO_AF_comp_val": "1" # AF1 is needed with PA5
                                  })

hardware_dict["TIM3_CH1"].update({"TIM": "3",
                                  "CHANNEL": "0",

                                  "PRESCALER_reg_offset": "40",
                                  "ARR_reg_offset": "44",

                                  "TIM_clk_en_reg_offset": "28", 
                                  "TIM_clk_en_bit_shift": "1", "TIM_clk_en_mask": "1", "TIM_clk_en_comp_val": "1",

                                  "TIM_control1_reg_offset": "0",
                                  "TIM_control1_bit_shift": "0", "TIM_control1_mask": "17", "TIM_control1_comp_val": "1",

                                  "TIM_mode_reg_offset": "24",
                                  "TIM_mode_bit_shift": "4", "TIM_mode_mask": "4103", "TIM_mode_comp_val": "6",

                                  "TIM_OC_pol_en_reg_offset": "32",
                                  "TIM_OC_pol_en_bit_shift": "0", "TIM_OC_pol_en_mask": "3", "TIM_OC_pol_en_comp_val": "1",

                                  "GPIO_AF_reg_offset": "32",
                                  "GPIO_AF_bit_shift": "24", "GPIO_AF_mask": "15", "GPIO_AF_comp_val": "2" # AF2 is needed for PA6
                                  })

hardware_dict["TIM3_CH2"].update({"TIM": "3",
                                  "CHANNEL": "1",

                                  "PRESCALER_reg_offset": "40",
                                  "ARR_reg_offset": "44",

                                  "TIM_clk_en_reg_offset": "28", 
                                  "TIM_clk_en_bit_shift": "1", "TIM_clk_en_mask": "1", "TIM_clk_en_comp_val": "1",

                                  "TIM_control1_reg_offset": "0",
                                  "TIM_control1_bit_shift": "0", "TIM_control1_mask": "17", "TIM_control1_comp_val": "1",

                                  "TIM_mode_reg_offset": "24",
                                  "TIM_mode_bit_shift": "12", "TIM_mode_mask": "4103", "TIM_mode_comp_val": "6",

                                  "TIM_OC_pol_en_reg_offset": "32",
                                  "TIM_OC_pol_en_bit_shift": "4", "TIM_OC_pol_en_mask": "3", "TIM_OC_pol_en_comp_val": "1",

                                  "GPIO_AF_reg_offset": "32",
                                  "GPIO_AF_bit_shift": "28", "GPIO_AF_mask": "15", "GPIO_AF_comp_val": "2" # AF2 is needed for PA7 or PC7
                                  })

hardware_dict["TIM16_CH1"].update({"TIM": "16",
                                  "CHANNEL": "0",

                                  "PRESCALER_reg_offset": "40",
                                  "ARR_reg_offset": "44",

                                  "TIM_clk_en_reg_offset": "24", 
                                  "TIM_clk_en_bit_shift": "17", "TIM_clk_en_mask": "1", "TIM_clk_en_comp_val": "1",

                                  "TIM_control1_reg_offset": "0",
                                  "TIM_control1_bit_shift": "0", "TIM_control1_mask": "1", "TIM_control1_comp_val": "1",

                                  "TIM_mode_reg_offset": "24",
                                  "TIM_mode_bit_shift": "4", "TIM_mode_mask": "4103", "TIM_mode_comp_val": "6",

                                  "TIM_OC_pol_en_reg_offset": "32",
                                  "TIM_OC_pol_en_bit_shift": "0", "TIM_OC_pol_en_mask": "3", "TIM_OC_pol_en_comp_val": "1",
                                
                                  "GPIO_AF_reg_offset": "32",
                                  "GPIO_AF_bit_shift": "24", "GPIO_AF_mask": "15", "GPIO_AF_comp_val": "1" # AF1 is needed for PA6
                                  })

# hardware_dict["TIM16_CH1N"].update({"TIM": "16",
#                                   "CHANNEL": "0",

#                                   "PRESCALER_reg_offset": "40",
#                                   "ARR_reg_offset": "44",

#                                   "TIM_clk_en_reg_offset": "24", 
#                                   "TIM_clk_en_bit_shift": "17", "TIM_clk_en_mask": "1", "TIM_clk_en_comp_val": "1",

#                                   "TIM_control1_reg_offset": "0",
#                                   "TIM_control1_bit_shift": "0", "TIM_control1_mask": "1", "TIM_control1_comp_val": "1",

#                                   "TIM_mode_reg_offset": "24",
#                                   "TIM_mode_bit_shift": "4", "TIM_mode_mask": "4103", "TIM_mode_comp_val": "6",

#                                   "TIM_OC_pol_en_reg_offset": "32",
#                                   "TIM_OC_pol_en_bit_shift": "2", "TIM_OC_pol_en_mask": "3", "TIM_OC_pol_en_comp_val": "1", # N
                                  
#                                   "GPIO_AF_reg_offset": "32",
#                                   "GPIO_AF_bit_shift": "28", "GPIO_AF_mask": "15", "GPIO_AF_comp_val": "1" # AF1 is needed for PB6
#                                   })

hardware_dict["TIM17_CH1"].update({"TIM": "17",
                                  "CHANNEL": "0",

                                  "PRESCALER_reg_offset": "40",
                                  "ARR_reg_offset": "44",

                                  "TIM_clk_en_reg_offset": "24", 
                                  "TIM_clk_en_bit_shift": "18", "TIM_clk_en_mask": "1", "TIM_clk_en_comp_val": "1",

                                  "TIM_control1_reg_offset": "0",
                                  "TIM_control1_bit_shift": "0", "TIM_control1_mask": "1", "TIM_control1_comp_val": "1",

                                  "TIM_mode_reg_offset": "24",
                                  "TIM_mode_bit_shift": "4", "TIM_mode_mask": "4103", "TIM_mode_comp_val": "6",

                                  "TIM_OC_pol_en_reg_offset": "32",
                                  "TIM_OC_pol_en_bit_shift": "0", "TIM_OC_pol_en_mask": "3", "TIM_OC_pol_en_comp_val": "1",
                                
                                  "GPIO_AF_reg_offset": "32",
                                  "GPIO_AF_bit_shift": "28", "GPIO_AF_mask": "15", "GPIO_AF_comp_val": "1" # AF2 is needed for PA7
                                  })






#################################################################

taskParameters = sys.argv[1].strip().split("#") # order is: frq(in Hz), duty(in %), pin, tim/channel
GPIO_key = taskParameters[2]
TIM_CHANNEL_key = taskParameters[3]
random_tag = sys.argv[2]
params = {}

simCycles = random.randrange(5, 30)
# periodClks = taskParameters >> 18
# dutyClks = taskParameters & (2**18 - 1)

#########################################
# SET PARAMETERS FOR TESTBENCH TEMPLATE #
#########################################
params.update(
    {
        "random_tag": random_tag,
        "FRQ": taskParameters[0],
        "DUTY": taskParameters[1],
        "PIN": taskParameters[2],
        "TIM_CHANNEL": taskParameters[3],
        "SIMCYCLES": simCycles,
    }
)

params.update(hardware_dict[GPIO_key])
params.update(hardware_dict[TIM_CHANNEL_key])

###########################
# FILL TESTBENCH TEMPLATE #
###########################
env = Environment()
env.loader = FileSystemLoader("templates/")
filename = "testbench_template.robot"
template = env.get_template(filename)
template = template.render(params)

print(template)
