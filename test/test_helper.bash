load "/usr/lib/bats/bats-support/load"
load "/usr/lib/bats/bats-assert/load"
load "/usr/lib/bats/bats-file/load"


function check_package {
    package="$1"

    run dpkg-query -Wf '${db:Status-abbrev}' "$package"
    assert_success
    assert_output --partial "ii"  # NOTE: full match gives a false negative
}


function check_service {
    service="$1"

    run systemctl is-enabled "$service"
    assert_success
    assert_output "enabled"

    # Check if the service is a oneshot, and skip the ActiveState check if so
    # NOTE: timers don't have a Type field, so $type is then empty, but the
    #       expected value of their ActiveState field is still "active"
    run systemctl show -p Type --value "$service"
    assert_success
    if [ "$output" == "oneshot" ]; then
        return 0
    fi

    run systemctl is-active "$service"
    assert_success
    assert_line "active"
}
