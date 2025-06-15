load test_helper


@test "check NetworkManager is installed" {
    check_package network-manager
}


@test "check resolved is installed" {
    check_package systemd-resolved
}


@test "check wpa_supplicant is enabled and running" {
    check_service wpa_supplicant
}


@test "check resolved is enabled and running" {
    check_service systemd-resolved
}


@test "check NetworkManager is enabled and running" {
    check_service NetworkManager
}


@test "check WiFi connection was established in NetworkManager" {
    run nmcli connection
    assert_success
    assert_line --partial "wifi"
}
