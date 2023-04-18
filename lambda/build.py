#!/usr/bin/python3
import os
import subprocess
import shutil

def main():
    """
    Creates the package folder, copies main.py, and install requirements.txt in it.
    Uses absolute paths to allow execution through shebang and through python3 build.py
    """
    MODULE_FOLDER =  os.path.dirname(__file__)
    PACKAGE_DIR = os.path.join(MODULE_FOLDER, "package")
    REQUIREMENTS_FILE = os.path.join(MODULE_FOLDER, "requirements.txt")
    MAIN_FILE = os.path.join(MODULE_FOLDER, "main.py")
    MAIN_FILE_BASE = os.path.basename(MAIN_FILE)
    
    
    try:
        print("CREATE PACKAGE DIR")
        os.mkdir(PACKAGE_DIR)
    except FileExistsError:
        print("FOLDER ALREADY EXISTS. SKIPING STEP")

    print("MOVE main.py")
    shutil.copy(MAIN_FILE, os.path.join(PACKAGE_DIR, MAIN_FILE_BASE))

    command = f'pip3 install --target {PACKAGE_DIR} -r {REQUIREMENTS_FILE}'
    print('RUN PIP')
    subprocess.run(command, shell=True)

if __name__ == "__main__":
    main()