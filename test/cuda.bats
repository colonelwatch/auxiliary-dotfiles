load test_helper


@test "check bolt service is enabled and running" {
	check_service bolt
}


@test "check if a CUDA device is ready" {
	run nvidia-smi
	assert_success
}
