load test_helper


@test "check cpupower-performance is enabled and running" {
	check_service cpupower-performance
}


@test "check governor is set" {
	run cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
	assert_output --regexp '^performance([[:space:]]performance)*$'
}


@test "check perf_bias is set" {
	perf_bias=$(< /sys/devices/system/cpu/cpu0/power/energy_perf_bias)
	assert_equal "$perf_bias" "0"
}
