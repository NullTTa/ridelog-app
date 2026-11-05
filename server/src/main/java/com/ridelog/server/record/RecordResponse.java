package com.ridelog.server.record;

import java.time.LocalDate;

public record RecordResponse(
        Long id,
        Category category,
        String categoryLabel,
        String title,
        Integer mileage,
        Integer cost,
        LocalDate serviceDate,
        String shop,
        String memo
) {
    public static RecordResponse from(MaintenanceRecord r) {
        return new RecordResponse(
                r.getId(),
                r.getCategory(),
                r.getCategory().getLabel(),
                r.getTitle(),
                r.getMileage(),
                r.getCost(),
                r.getServiceDate(),
                r.getShop(),
                r.getMemo()
        );
    }
}
