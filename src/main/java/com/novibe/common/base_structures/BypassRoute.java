package com.novibe.common.base_structures;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.experimental.Accessors;

@Data
@Accessors(fluent = true)
@AllArgsConstructor
public final class BypassRoute {
    private String ip;
    private String website;
}
