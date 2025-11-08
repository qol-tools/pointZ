use std::net::IpAddr;
use if_addrs::get_if_addrs;

pub fn get_local_ip() -> Option<IpAddr> {
    get_if_addrs()
        .ok()?
        .iter()
        .find(|iface| !iface.is_loopback() && iface.ip().is_ipv4())
        .map(|iface| iface.ip())
}

