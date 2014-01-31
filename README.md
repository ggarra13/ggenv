
 == Documentation

 This file contains auxiliary routines to easily interact with 
 environment variables that contain lists of paths, like PATH, 
 LD_LIBRARY_PATH, MAYA_SCRIPT_PATH, etc.

 == Usage

  Env.check_directories = false        turn off verification that
                                       directories exist (default: true)
  path = Env['PATH']

  path << "C:/newpath"                 As path is modified, so 
                                       is ENV['PATH']

  path.delete_if { |x| x =~ /maya/ }   remove all paths that have maya

  path.unshift ["C:/", "E:/bin"]       add these paths at start

  Env['PATH'] = path[0,2] + path[4,6]  concat two slices and send to PATH

  path.check_directories               check existance of directories
                                       for this variable only (unlike
                                       Env.check_directories)
