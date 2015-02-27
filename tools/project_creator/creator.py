# -*- coding: utf-8 -*-

import os
import sys
import uuid
import shutil

helper = '''
**************************************************
create a new project
creator your_prj_name
**************************************************
'''

def format_file(path, *args):
	f = open(path, "r")
	fmt = f.read()
	f.close()
	text = fmt % args
	f = open(path, "w")
	f.write(text)
	f.close()


def create_msvc(prj_name, folder):
	builder = os.path.join(folder, "build")
	sln = os.path.join(builder, prj_name+".sln")
	prj_dir = os.path.join(builder, prj_name)
	guid = uuid.uuid1()

	#solution file
	os.rename(os.path.join(builder, "example.sln"), sln)
	format_file(sln, prj_name, prj_name, prj_name, guid)

	#vc project
	os.rename(os.path.join(builder, "example"), prj_dir)

	file_list=("%s.vcxproj", "%s.vcxproj.filters", "%s.vcxproj.user")
	for i in file_list:
		os.rename(os.path.join(prj_dir, i%"example"), os.path.join(prj_dir, i%prj_name))
	args=(guid, prj_name, "%(AdditionalIncludeDirectories)", "%(PreprocessorDefinitions)", "%(AdditionalDependencies)")
	format_file(os.path.join(prj_dir, "%s.vcxproj"%prj_name), *args)

	print("msvc project created")

def create_ios(prj_name, folder):
	xcodeproj = os.path.join(folder, prj_name+".xcodeproj")
	os.rename(os.path.join(folder, "example"), os.path.join(folder, prj_name))
	os.rename(os.path.join(folder, "example.xcodeproj"), xcodeproj)

	pbxproj = os.path.join(xcodeproj, "project.pbxproj")
	f = open(pbxproj, "r")
	txt = f.read()
	f.close()
	txt = txt.replace("example", prj_name)
	f = open(pbxproj, "w")
	f.write(txt)
	f.close()

	print("ios xcode project created")

def main(prj_name):
	py_path = os.getcwd()
	root = os.path.join(py_path, "../../project")
	tpl_dir = os.path.join(py_path, "template")
	prj_dir = os.path.join(root, prj_name)
	if os.path.exists(prj_dir) and (os.path.exists(os.path.join(prj_dir, "asset")) or\
			os.path.exists(os.path.join(prj_dir, "script")) or\
			os.path.exists(os.path.join(prj_dir, "platform"))):
		raise Exception("the project directory is exists:"+prj_dir)

	for i in os.listdir(tpl_dir):
		shutil.copytree(os.path.join(tpl_dir, i), os.path.join(prj_dir, i))

	create_msvc(prj_name, os.path.join(prj_dir, "platform/msvc"))
	create_ios(prj_name, os.path.join(prj_dir, "platform/ios"))

if __name__ == '__main__':
	if len(sys.argv) >= 2:
		main(sys.argv[1])
	else:
		print("no prj_name")
		print(helper)
