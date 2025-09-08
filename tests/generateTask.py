#!/usr/bin/env python3

########################################################################
# generateTask.py for STM32 task pwm
# Generates random tasks, generates TaskParameters, fill
# entity and description templates
#
# Copyright (C) 2015 Martin  Mosbeck   <martin.mosbeck@gmx.at>
# License GPL V2 or later (see http://www.gnu.org/licenses/gpl2.txt)
########################################################################

import random
import sys

from jinja2 import FileSystemLoader, Environment
#################################################################

userId=sys.argv[1]
taskNr=sys.argv[2]
submissionEmail=sys.argv[3]
language=sys.argv[4]

paramsDesc={}

# for task one, frequency between 0.5 and 2 Hz
freqs_possible = [0.5, 0.8, 1, 1.6, 2]
chosen_freq = freqs_possible[random.randrange(len(freqs_possible))] # choses random frequency from possible list

# available pins and channels
pin_channel_combinations = {"PA5":"TIM2_CH1", 
                            "PA6":"TIM3_CH1",
                            "PA7":"TIM3_CH2",
                            "PC7":"TIM3_CH2"
                            }
pins_possible = ["PA5", "PA6", "PA7", "PC7"]
chosen_pin = pins_possible[random.randrange(len(pins_possible))] # random pin chosen

#duty between 10 and 90%
chosen_duty=random.randrange(10,91) # excludes 91

##############################
## PARAMETER SPECIFYING TASK##
##############################
taskParameters= f"{chosen_freq:.1f}#{chosen_duty}#{chosen_pin}#{pin_channel_combinations[chosen_pin]}"

############### ONLY FOR TESTING #######################
filename ="tmp/solution_{0}_Task{1}.txt".format(userId,taskNr)
with open (filename, "w") as solution:
    solution.write("Chosen TaskParameters:\n")
    for text, param in zip(["Frequency:", "Duty:", "Pin:", "Timer/Channel:"], taskParameters.split("#")):
        solution.write(f"{text}\t{param}\n")


###########################################
# SET PARAMETERS FOR DESCRIPTION TEMPLATE #
###########################################
# FRQ  Frequency
# DUTY Duty Cycle
# PIN pin
paramsDesc.update({"FRQ":f"{chosen_freq:.1f}", "DUTY":f"{chosen_duty}", "PIN":chosen_pin})
paramsDesc.update({"TASKNR":str(taskNr),"SUBMISSIONEMAIL":submissionEmail})

#############################
# FILL DESCRIPTION TEMPLATE #
#############################
env = Environment()
env.loader = FileSystemLoader('templates/')
filename ="task_description/task_description_template_{0}.tex".format(language)
template = env.get_template(filename)
template = template.render(paramsDesc)

filename ="tmp/desc_{0}_Task{1}.tex".format(userId,taskNr)
with open (filename, "w") as output_file:
    output_file.write(template)

###########################
### PRINT TASKPARAMETERS ##
###########################
print(taskParameters)   # "returns" task parameters to give it on to taskBench generator 
