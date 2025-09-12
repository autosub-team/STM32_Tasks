#!/usr/bin/env python3

########################################################################
# generateTask.py for STM32 task pwm with single led
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

# for task two, one rgb channel shall have a slow frequency between 1 and 35 Hz, the other shall have a higher above 100 Hz until 5000 Hz
# freqs_possible_slow = []
# freqs_possible_fast = []

# ARR_slow = 15999 # breaks cpu freq down to 4 kHz
# for f_tim in range(1, 36):
#     PS = (64000000/f_tim) / (1 + ARR_slow) - 1
#     if (PS % 1) == 0 and PS < 2**16: # whole number
#         freqs_possible_slow.append(f_tim)
    
# ARR_fast = 159 # breaks cpu freq down to 400 kHz
# for f_tim in range(100, 5001, 100):
#     PS = (64000000/f_tim) / (1 + ARR_fast) - 1
#     if (PS % 1) == 0 and PS < 2**16: # whole number
#         freqs_possible_fast.append(f_tim)

# print(f"Slow available frequencies:\n{freqs_possible_slow}")

# print(f"fast available frequencies:\n{freqs_possible_fast}")

# previously calculated:
freqs_possible_slow = [1, 2, 4, 5, 8, 10, 16, 20, 25, 32]
freqs_possible_fast = [100, 200, 400, 500, 800, 1000, 1600, 2000, 2500, 3200, 4000, 5000]


# choses random frequency from possible list
freqs = [freqs_possible_slow[random.randrange(len(freqs_possible_slow))],  freqs_possible_fast[random.randrange(len(freqs_possible_fast))]]

#duty between 10 and 90%
dutys= [random.randrange(10,91), random.randrange(10,91)] # excludes 91

# pins and channels are fixed since rgb green is only possible with PC7 and TIM3_CH2, and therefore only TIM17_CH1 is still available for rgb red on PA7
rgb_red_idx = random.randrange(2)
rgb_green_idx = (rgb_red_idx + 1) % 2 # if red is 1, green becomes 0, if red was 0, green becomes 1

##############################
## PARAMETER SPECIFYING TASK##
##############################
freq_red = freqs[rgb_red_idx]
duty_red = dutys[rgb_red_idx]
freq_green = freqs[rgb_green_idx]
duty_green = dutys[rgb_green_idx]

taskParameters= f"{freq_red}#{duty_red}#{freq_green}#{duty_green}"

############### ONLY FOR TESTING #######################
filename ="tmp/solution_{0}_Task{1}.txt".format(userId,taskNr)
with open (filename, "w") as solution:
    solution.write("Chosen TaskParameters:\n")
    for text, param in zip(["Frequency_red:", "Duty_red:", "Frequency_green:", "Duty_green:"], taskParameters.split("#")):
        solution.write(f"{text}\t{param}\n")


###########################################
# SET PARAMETERS FOR DESCRIPTION TEMPLATE #
###########################################
# FRQ  Frequency
# DUTY Duty Cycle
# PIN pin
paramsDesc.update({"FRQred":f"{freq_red}", "DUTYred":f"{duty_red}"})
paramsDesc.update({"FRQgreen":f"{freq_green}", "DUTYgreen":f"{duty_green}"})
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
