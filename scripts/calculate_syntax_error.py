#!/usr/bin/python
# -*- coding: utf-8 -*-
import os
import shutil
import subprocess


path = "./samples/"
dest = "./samples/"
file_type_list = ["js"]
num_of_samples = 0
num_of_syntaxError = 0
num_of_typeError = 0
num_of_ReferenceError = 0
num_of_RangeError = 0
num_of_valid = 0


def listfiles(path):
    global num_of_samples, num_of_syntaxError, num_of_typeError, num_of_ReferenceError, num_of_RangeError, num_of_valid
    for file in os.listdir(path):
        listpath = path + file
        if os.path.isdir(listpath):
            listfiles(listpath)
        elif os.path.isfile(listpath):
            print("\n" + listpath)
            print("num_of_samples:" + str(num_of_samples))
            print("num_of_syntaxError:" + str(num_of_syntaxError))
            print("num_of_ReferenceError:" + str(num_of_ReferenceError))
            print("num_of_typeError:" + str(num_of_typeError))
            print("num_of_RangeError:" + str(num_of_RangeError))
            num_of_samples += 1
            try:
                ret = subprocess.check_output(["./WebKit/FuzzBuild/Debug/bin/jsc", listpath],
                                              stderr=subprocess.STDOUT, universal_newlines=True,
                                              timeout=1)
                # os.rename(listpath, dest + file)
            except subprocess.CalledProcessError as e:
                print("return code: " + str(e.returncode))
                if e.returncode == 3:
                    if "Exception: SyntaxError:" in e.stdout:
                        num_of_syntaxError += 1
                        #shutil.move(listpath, "/home/b/zhunki/crossover/pymodules/SyntaxError/"+file)
                        # print(e.stdout)
                    elif "Exception: TypeError:" in e.stdout:
                        num_of_typeError += 1
                        #shutil.move(listpath, "/home/b/zhunki/crossover/pymodules/TypeError/"+file)
                        # print(e.stdout)
                    elif "Exception: ReferenceError:" in e.stdout:
                        num_of_ReferenceError += 1
                        #shutil.move(listpath, "/home/b/zhunki/crossover/pymodules/ReferenceError/"+file)
                        # print(e.stdout)
                    elif "Exception: RangeError:" in e.stdout:
                        num_of_RangeError += 1
                        #shutil.move(listpath, "/home/b/zhunki/crossover/pymodules/RangeError/"+file)
                        # print(e.stdout)
                    # else:
                    # print(e.stdout)
                pass
                    
            except subprocess.TimeoutExpired as e:
                # print(e.output)
                pass
                # os.rename(listpath, dest + file)
            else:
                #os.remove(listpath)
                num_of_valid+=1

    print("num_of_samples:" + str(num_of_samples))
    print("valid samples:" + str(num_of_valid))


def calculate_error(path):
    listfiles(path)


if __name__ == '__main__':
    calculate_error(path)