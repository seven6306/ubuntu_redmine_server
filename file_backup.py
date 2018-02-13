from sys import argv
from shtuil import copy
from os import remove, makedirs
from os.path import join, isfile, isdir, basename

def backup(files):
    try:
        if not isdir('backup'):
            makedirs('backup')
        for each_file in files.split(','):
            bak = join('backup', basename(each_file))
            if isfile(bak):
                remove(bak)
            copy(each_file, bak)
    except Exception as err:
        print str(err)
    
if __name__ == '__main__':
    if len(argv) == 2:
        files = argv[1]
        backup(files)
    else:
        'Usage: python file_backup.py [Files]\ne.g., python file_backup.py /etc/apache2/mods-available/passenger.conf,/etc/apache2/sites-available/000-default.conf'
