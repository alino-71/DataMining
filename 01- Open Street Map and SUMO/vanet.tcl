# set number of nodes
set opt(nn) 50

# set activity file
set opt(af) $opt(config-path)
append opt(af) /activity.tcl

# set mobility file
set opt(mf) $opt(config-path)
append opt(mf) /mobility2.tcl

# set start/stop time
set opt(start) 0.0
set opt(stop) 1000.0

# set floor size
set opt(x) 3073.66
set opt(y) 1876.98
set opt(min-x) 1771.92
set opt(min-y) 410.11

