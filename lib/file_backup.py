#!/usr/bin/python
from sys import argv
from shtuil import copy
from os import remove, makedirs
from os.path import join, isfile, isdir, basename

def backup(files):
    try:
        if not isdir('backup'):
            makedirs('backup')
            print " * Create backup directory at currently path."
        for each_file in files.split(','):
            bak = join('backup', basename(each_file))
            if isfile(bak):
                remove(bak)
            copy(each_file, bak)
            print " * Backup file: \033[0;32m{}\033[0m".format(each_file)
        return True
    except Exception as err:
        print str(err)
    
if __name__ == '__main__':
    if len(argv) == 2:
        files = argv[1]
        if not backup(files):
            raise SystemExit(2)
    else:
        print 'Usage: python file_backup.py [Files]\n       e.g., python file_backup.py /home/blake/bak1.conf,/home/blake/bak2.txt'
