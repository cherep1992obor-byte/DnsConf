package com.novibe.common.base_structures;

import lombok.Builder;

@Builder
public record DnsProfile(String dnsProvider, String clientId, String authSecret, int number, String donorDns) {
}