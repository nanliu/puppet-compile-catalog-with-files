node default {
  $mynotice = $operatingsystem ? {
    Ubuntu => 'ubuntu',
    default => 'blah',
  }
  notify { $externalnodetest : }
  notify { $mynotice : }
  $myfile = $operatingsystem ? {
    Ubuntu => 'ubuntu',
    default => 'foo',
  }

  # file exists
  file { "/tmp/$myfile" :
    mode => 644,
    source => "puppet:///modules/mymodule/$myfile"
  }
  # secondmodule with a file that exists in a subdirectory
  file { "/tmp/secondmodbar" :
    source => "puppet:///modules/mysecondmodule/subdir1/subdir2/filezor.ext"
  }
# # file doesn't exist doesn't get included in the tar
# file { "/tmp/bar" :
#   source => "puppet:///modules/myothermodule/bar"
# }
  # shouldn't try to get local sources
  file { "/tmp/baz" :
    source => "/tmp/one.csv"
  }
  # shouldn't try to get content files
  file { "/tmp/boo" :
    content => "hello boo"
  }
}

# making sure it does something different for nodes that ask for it
node realnode {
  notify { 'realnodefoo' : }
}
