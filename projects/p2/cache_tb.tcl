;# add waves to the Wave window

proc AddWaves {} {
	add wave -position end  sim:/cache_tb/reset
	add wave -position end  sim:/cache_tb/clk
	add wave -position end  sim:/cache_tb/s_addr
	add wave -position end  sim:/cache_tb/s_read
	add wave -position end  sim:/cache_tb/s_readdata
	add wave -position end  sim:/cache_tb/s_write
	add wave -position end  sim:/cache_tb/s_writedata
	add wave -position end  sim:/cache_tb/s_waitrequest
	add wave -position end  sim:/cache_tb/m_addr
	add wave -position end  sim:/cache_tb/m_read
	add wave -position end  sim:/cache_tb/m_readdata
	add wave -position end  sim:/cache_tb/m_write
	add wave -position end  sim:/cache_tb/m_writedata
	add wave -position end  sim:/cache_tb/m_waitrequest
}

vlib work

;# compile components
vcom memory.vhd
vcom cache.vhd
vcom cache_tb.vhd

;# start simulation
vsim -t ps work.cache_tb

;# add the waves
AddWaves

;# run for 1500 ns
run 1500 ns
