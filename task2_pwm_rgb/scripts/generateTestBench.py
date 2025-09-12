#!/usr/bin/env python3

########################################################################
# generateTestBench.py for STM32 task pwm rgb
# Generates testvectors and fills a testbench for specified taskParameters
#
# Copyright (C) 2015 Martin  Mosbeck   <martin.mosbeck@gmx.at>
# License GPL V2 or later (see http://www.gnu.org/licenses/gpl2.txt)
########################################################################

import sys
import random

from jinja2 import FileSystemLoader, Environment


##################### Hardware Information ######################
# for this task, the hardware is predefined and therefore directly written into the testbench template




#################################################################

taskParameters = sys.argv[1].strip().split("#") # order is: frq_red(in Hz), duty_red(in %), pin_red, tim/channel_red, frq_green(in Hz), duty_green(in %), pin_green, tim/channel_green
random_tag = sys.argv[2]
params = {}

simCycles = random.randrange(5, 30)

#########################################
# SET PARAMETERS FOR TESTBENCH TEMPLATE #
#########################################
params.update(
    {
        "random_tag": random_tag,
        "FRQ_RED": taskParameters[0],
        "DUTY_RED": taskParameters[1],
        "FRQ_GREEN": taskParameters[2],
        "DUTY_GREEN": taskParameters[3],
        "SIMCYCLES": simCycles,
    }
)


###########################
# FILL TESTBENCH TEMPLATE #
###########################
env = Environment()
env.loader = FileSystemLoader("templates/")
filename = "testbench_template.robot"
template = env.get_template(filename)
template = template.render(params)

print(template)
