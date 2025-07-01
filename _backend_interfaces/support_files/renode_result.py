from robot.api import ExecutionResult, ResultVisitor
import sys
from tabulate import tabulate



class MyResultVisitor(ResultVisitor):
    def __init__(self, error_file='error_msg'):
        self.table = []
        self.error_file = error_file

    def visit_test(self, test):
        self.table.append([test.name, test.status, test.message])

    def end_result(self, result):
        # Create a new error_file
        with open(self.error_file, "a") as f:
            f.write(tabulate(self.table, headers=["Test", "Passed/Failed", "Msg"], tablefmt='grid'))

                
if __name__ == '__main__':
    try:
        output_file = sys.argv[1]
    except IndexError:
        output_file = "output.xml"
    try:
        error_file = sys.argv[2]
    except IndexError:
        error_file = "error_msg"
    result = ExecutionResult(output_file)
    result.visit(MyResultVisitor(error_file))