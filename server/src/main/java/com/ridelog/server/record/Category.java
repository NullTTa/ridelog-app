package com.ridelog.server.record;

/**
 * 정비 분류 + 권장 교체 주기(km). 0이면 주기 없음.
 */
public enum Category {
    ENGINE_OIL("엔진오일", 3000),
    TIRE("타이어", 15000),
    BRAKE("브레이크", 10000),
    CHAIN("체인/스프라켓", 15000),
    BATTERY("배터리", 0),
    ETC("기타", 0);

    private final String label;
    private final int intervalKm;

    Category(String label, int intervalKm) {
        this.label = label;
        this.intervalKm = intervalKm;
    }

    public String getLabel() {
        return label;
    }

    public int getIntervalKm() {
        return intervalKm;
    }
}
