package com.ridelog.server.record;

import java.util.List;

/**
 * 홈 화면 상단 요약 카드용 응답
 */
public record SummaryResponse(
        long totalCount,
        long totalCost,
        int latestMileage,
        List<NextService> nextServices
) {
    /**
     * 분류별 다음 정비 예정 주행거리
     */
    public record NextService(
            Category category,
            String categoryLabel,
            int lastMileage,
            int nextMileage,
            int remainingKm
    ) {
    }
}
