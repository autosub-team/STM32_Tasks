######################################################################################
# Common file for all testers using renode/robot
#
# Copyright (C) 2025 Philipp-S. Vogt <philippvogt@gmx.at>
# Copyright (C) 2018 Martin  Mosbeck <martin.mosbeck@tuwien.ac.at>
#
# License GPL V2 or later (see http://www.gnu.org/licenses/gpl2.txt)
######################################################################################

######################################
#               SET UP               #
######################################

zero=0
one=1

# local error codes for testing sequenz (needed to clarify which log files should be saved)
FAILURE_NOATTACH=1
FAILURE_VELSANALYZE=2
FAILURE_USERANALYZE=3
FAILURE_ELABORATE=4
FAILURE_SIM=5
SUCCESS_SIM=6
FAILURE_UNHANDLED=7

#path to support files for backend_interfaces scripts
support_files_path=$backend_interfaces_path/support_files

#path to autosub
autosub_path=$(pwd)

# path for all the files that describe the created task
desc_path="$autosub_path/users/${user_id}/Task${task_nr}/desc"

#path where the testing takes place
user_task_path="$autosub_path/users/${user_id}/Task${task_nr}"

# testbench file
testbench=${task_name}_tb_${user_id}_Task${task_nr}.robot

# name of testbench entity
testbench_ent=${task_name}_tb

# DEBUG OUTPUT
#echo "tb_entity:${testbench_ent}"
#echo "user_task_path= $user_task_path"
#echo "desc_path= $desc_path"
#echo "task_path= $task_path"
#echo "autosub_path= $autosub_path"
#echo "backend_interfaces_path= $backend_interfaces_path"
#echo "support_files_path=$support_files_path"
#echo "---------------------------------------"

######################################
#       FUNCTIONS FOR TESTING        #
######################################

# generate random tag, this tag has to be attached to the Success output and is
# checked. Otherwise students could trick the system by reporting "Success" in
# their behavior file
random_tag=$(openssl rand -hex 6)

#
#-------------------------------------------------------------------------------
#

function generate_testbench {
	cd $task_path
	#generate the testbench
	python3 scripts/generateTestBench.py "$task_params" "$random_tag" > $user_task_path/$testbench
}

#
#-------------------------------------------------------------------------------
#

function desccp {
	cp $desc_path/$1 $user_task_path
}

#
#-------------------------------------------------------------------------------
#

function prepare_test {
	cd $user_task_path

	# create tmp directory for user if it does not exist
	if [ ! -d "/tmp/$USER" ]
	then
		mkdir /tmp/$USER
	fi

	# create file for error messages, which will be sent to user
	touch error_msg

	#make sure the error_attachments folder is empty
	if [ ! -d "error_attachments" ];
	then
		mkdir error_attachments
	else
		rm -r error_attachments
		mkdir error_attachments
	fi

	#------ CHECK AND PREPARE USERFILES ------
	for userfile in $userfiles
	do
		#check if the user supplied a file
		if [ ! -f $userfile ]
		then
			echo "Error with task ${task_nr}. User ${user_id} did not attach the right file."
			echo "You did not attach your solution. Please attach the file $userfile" > error_msg
			exit_and_save_results $FAILURE_NOATTACH
		fi

		# delete comments from the file to allow checks like looking for 'wait'
		# NOTE: this is not a parse and does not cover 2008 multi line
		# comments, but should work for most cases
		sed -i 's:--[^"]*$::g' $userfile


		# SECURITY filter
		# check if certain words are not used (e.g. file_handler to read or write files)
                # list of words is stored in "illegal_words.txt" in the backend_interface directory
                # NOTE: whitespaces are also relevant in the txt file
                if [ -f $backend_interfaces_path/support_files/illegal_words.txt ]
                then
                    while IFS="" read -r p || [ -n "$p" ]
                    do
                        egrep -ioq "$p" $userfile
                        RET=$?
                        if [ "$RET" -eq "$zero" ]
                        then
                            echo "Do not use the keyword '$p'. Otherwise I might think that you are trying to be naughty?!" > error_msg
		            exit $SECURITYALERT
                        fi
                    done <$backend_interfaces_path/support_files/illegal_words.txt
                fi
	done

	#------ COPY NEEDED FILES FOR TEST ------
	for filename in $entityfiles
	do
		desccp $filename
	done

	for filename in $extrafiles
	do
		desccp $filename
	done

}


#
#-------------------------------------------------------------------------------
#

function generate_cmake_bin {
	cd $user_task_path
	cmake -S . -B build
	cmake --build build 2> error_msg
	RET_timeout=$?
	if [ "$RET_timeout" -ne 0 ]
	then
		exit_and_save_results $FAILURE_USERANALYZE
	fi
}

function run_renode {
	cd $user_task_path

	# set virtual memory limit to 500 MiB
	#ulimit -v $((500*1024))

	# start simulation, output is written to a file called transcript, no need
	# to output the error messages to stderr, as they are also in the transcript
	renode-test ${testbench} -r renode --test-timeout $simulation_timeout
	RET_timeout=$?

	if [ "$RET_timeout" -eq 1 ]
	then
		python3 $support_files_path/renode_result.py renode/robot_output.xml error_msg
		exit_and_save_results $FAILURE_SIM
	fi

	exit_and_save_results $SUCCESS_SIM
}

#
#-------------------------------------------------------------------------------
#

############################################################################################################
# before exiting the simulation, first copy all relevant simulation and log files to the submission folder #
############################################################################################################
function exit_and_save_results {

	########################################################################################
	# generate subfolder inside submission folder for saving the simulation and log files  #
	########################################################################################

	# find last submission number
	submission_nrs=($(ls $user_task_path | grep -oP '(?<=Submission)[0-9]+' | sort -nr))
	submission_nr_last=${submission_nrs[0]}

	# jump into last submission folder and get the correct name (name includes time, which is unknown to this script)
	cd $user_task_path/Submission${submission_nr_last}_*
	user_submission_path="$user_task_path/${PWD##*/}"

	# create subfolder test_results
	if [ ! -d "test_results" ]
	then
		mkdir test_results
	fi

	# jump back to user task path
	cd $user_task_path

	####################################################
	# always save the error message and used testbench #
	####################################################
	if [ -f $user_task_path/error_msg ]
	then
		src=$user_task_path/error_msg
		tgt=$user_submission_path/test_results/error_msg
		cp $src $tgt
	fi

	#copy testbench into task_results folder
	if [ -f $user_task_path/$testbench ]
	then
		src=$user_task_path/$testbench
		tgt=$user_submission_path/test_results/${task_name}_tb_${user_id}_Task${task_nr}.robot
		cp $src $tgt
	fi

	##############################################################################
	# depending on point of exit during test phase, save the relevant log files  #
	##############################################################################
	touch $user_submission_path/test_results/submission_log

	# Failure: user attached not the correct files
	if [ $1 = $FAILURE_NOATTACH ]
	then
		echo "User has not attached the correct files, so no simulation was started." > $user_submission_path/test_results/submission_log
		exit $FAILURE

	# Failure: VELS files (not files from user) throw error
	elif [ $1 = $FAILURE_VELSANALYZE ]
	then
		echo "Error while analyzing files which are not from the user, please have a look at the global task error log." > $user_submission_path/test_results/submission_log
		if [ -f $user_task_path/error_msg ]
		then
			src=/tmp/taskfiles_output_${user_id}_Task${task_nr}.txt
			tgt=$user_submission_path/test_results/taskfiles_output_${user_id}_Task${task_nr}.txt
			mv $src $tgt
		fi

		exit $TASKERROR

	# Failure: Analyzing user files throws error
	elif [ $1 = $FAILURE_USERANALYZE ]
	then
		echo "Error while analyzing user files." > $user_submission_path/test_results/submission_log

		if [ -f /tmp/$USER/tmp_Task${task_nr}_User${user_id} ]
		then
			src=/tmp/$USER/tmp_Task${task_nr}_User${user_id}
			tgt=$user_submission_path/test_results/tmp_Task${task_nr}_User${user_id}
			mv $src $tgt
		fi
		exit $FAILURE

	# Failure: Elaboration failed. NOT POSSIBLE WITH QUESTASIM
	#elif [ $1 = $FAILURE_ELABORATE ]
	#then

        # Failure: Simulation fails (either timeout, user syntax error or wrong behaviour)
	elif [ $1 = $FAILURE_SIM ]
	then
		echo "Simulation failed: either timeout, user syntax error or wrong behaviour." > $user_submission_path/test_results/submission_log

		if [ -f $user_task_path/renode/robot_output.xml ]
		then
			src=$user_task_path/renode/robot_output.xml
			tgt=$user_submission_path/test_results/robot_output.xml
			mv $src $tgt
		fi
		exit $FAILURE

	# Success
	elif [ $1 = $SUCCESS_SIM ]
	then
		echo "Simulation was successfull, correct solution." > $user_submission_path/test_results/submission_log

		if [ -f $user_task_path/renode/robot_output.xml ]
		then
			src=$user_task_path/renode/robot_output.xml
			tgt=$user_submission_path/test_results/robot_output.xml
			mv $src $tgt
		fi
		exit $SUCCESS

        # Failure: Unhandled failure occured
	elif [ $1 = $FAILURE_UNHANDLED ]
	then
		echo "Unhandled error occured" > $user_submission_path/test_results/submission_log

		if [ -f /tmp/$USER/tmp_Task${task_nr}_User${user_id} ]
		then
			src=/tmp/$USER/tmp_Task${task_nr}_User${user_id}
			tgt=$user_submission_path/test_results/tmp_Task${task_nr}_User${user_id}
			mv $src $tgt
		fi

		exit $FAILURE
	fi
}