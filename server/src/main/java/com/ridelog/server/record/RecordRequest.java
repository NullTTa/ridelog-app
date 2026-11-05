package com.ridelog.server.record;

import jakarta.validation.constraints.*;

import java.time.LocalDate;

public record RecordRequest(
        @NotNull Category category,
        @NotBlank @Size(max = 100) String title,
        @NotNull @PositiveOrZero Integer mileage,
        @NotNull @PositiveOrZero Integer cost,
        @NotNull LocalDate serviceDate,
        @Size(max = 100) String shop,
        @Size(max = 500) String memo
) {
}
