package com.novibe.common.data_sources;

import com.novibe.common.base_structures.BypassRoute;
import com.novibe.common.base_structures.HostsLine;
import org.springframework.stereotype.Service;

import java.util.function.Predicate;

@Service
public class HostsOverrideListsLoader extends ListLoader<BypassRoute> {

    @Override
    protected String listType() {
        return "Override";
    }

    @Override
    protected Predicate<HostsLine> filterRelatedLines() {
        return line -> line.hasIpAndDomain() && !HostsBlockListsLoader.isBlockIp(line.ip());

    }

    @Override
    protected BypassRoute toObject(HostsLine line) {
        return new BypassRoute(line.ip(), line.domain());
    }

}
