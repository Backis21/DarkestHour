import os
import sys
import getopt
import subprocess
import time
import ConfigParser
import shutil
from datetime import datetime
from collections import OrderedDict

class MultiOrderedDict(OrderedDict):
    def __setitem__(self, key, value):
        if isinstance(value, list) and key in self:
            self[key].extend(value)
        else:
            super(OrderedDict, self).__setitem__(key, value)

def print_usage():
	print "usage: make.py --mod=<ModName>"

def main(argv):
	#red orchestra directory
	ro_dir = os.environ.get('RODIR')

	if ro_dir == None:
		print "error: environment variable RODIR is not defined"
		sys.exit(1)

	if not os.path.isdir(ro_dir):
		print "error: environment variable RODIR is not a valid directory"
		sys.exit(1)

	#red orchestra system directory
	ro_sys_dir = os.path.join(ro_dir, 'System')

	if not os.path.isdir(ro_sys_dir):
		print "error: could not resolve red orchestra system directory"
		sys.exit(1)

	#parse options
	try:
		opts, args = getopt.getopt(argv, "c", ["mod="])
	except:
		print "error: invalid arguments"
		print_usage()
		sys.exit(1)

	mod = None
	should_clean = False

	print opts

	for opt, arg in opts:
		if opt == "--mod":
			mod = arg
		elif opt == "--clean":
			should_clean = True

	if mod == None:
		print "error: could not resolve mod"
		print_usage()
		sys.exit(1)

	#mod directory
	mod_dir = os.path.join(ro_dir, mod)

	if not os.path.isdir(mod_dir):
		print "error: could not resolve mod directory"
		sys.exit(1)

	#mod system directory
	mod_sys_dir = os.path.join(mod_dir, "System")

	if not os.path.isdir(mod_sys_dir):
		print "error could not resolve mod system directory"
		sys.exit(1)

	#mod config path
	config_path = os.path.join(mod_sys_dir, mod + ".ini")
	
	if not os.path.isfile(config_path):
		print "error: could not resove mod config file"
		sys.exit(1)

	#parse config
	config = ConfigParser.RawConfigParser(dict_type=MultiOrderedDict)
	config.read(config_path)

	packages = config.get("Editor.EditorEngine", "editpackages")

	packages_to_compile = []

	for package in packages:
		ro_sys_package_path = os.path.join(ro_sys_dir, package + ".u")

		if os.path.isfile(ro_sys_package_path):
			#compiled file exists in root system folder
			continue

		mod_sys_package_path = os.path.join(mod_sys_dir, package + ".u")

		#get package modified time
		package_mtime = 0.0

		if os.path.isfile(mod_sys_package_path):
			package_mtime = os.path.getmtime(mod_sys_package_path)

		should_compile_package = False
		package_src_dir = os.path.join(ro_dir, package, "Classes")

		for root, dirs, files in os.walk(package_src_dir):
			for file in files:
				if not file.endswith(".uc"):
					continue

				filename = os.path.join(root, file)
				file_mtime = os.path.getmtime(filename)

				if os.path.getmtime(filename) > package_mtime:
					should_compile_package = True
					packages_to_compile.append(package + ".u")
					break

			if should_compile_package:
				break

	if len(packages_to_compile) == 0:
		print "no packages to compile"
		return

	for package in packages_to_compile:
		package_path = os.path.join(mod_sys_dir, package)

		if os.path.isfile(package_path):
			try:
				os.remove(package_path)
			except:
				print "error: failed to delete file " + package + " (do you have the game or editor running?)"
				sys.exit(1)

	proc = subprocess.Popen([os.path.join(ro_sys_dir, "ucc"), "make", "-mod=" + mod])
	proc.communicate()

	for root, dirs, files in os.walk(ro_sys_dir):
		for file in files:
			if file in packages_to_compile:
				shutil.copy(os.path.join(root, file), mod_sys_dir)
				os.remove(os.path.join(root, file))

if __name__ == "__main__":
   main(sys.argv[1:])
