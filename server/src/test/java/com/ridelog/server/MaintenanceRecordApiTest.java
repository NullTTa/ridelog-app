package com.ridelog.server;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = "spring.datasource.url=jdbc:h2:mem:testdb")
@AutoConfigureMockMvc
class MaintenanceRecordApiTest {

    @Autowired
    MockMvc mvc;

    @Test
    void 등록_조회_요약_삭제() throws Exception {
        String body = """
                {"category":"ENGINE_OIL","title":"엔진오일 교체","mileage":12000,
                 "cost":35000,"serviceDate":"2026-11-01","shop":"부평 바이크","memo":"10W-30"}
                """;

        mvc.perform(post("/api/records")
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.categoryLabel").value("엔진오일"));

        mvc.perform(get("/api/records"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].title").value("엔진오일 교체"));

        mvc.perform(get("/api/summary"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalCost").value(35000))
                .andExpect(jsonPath("$.nextServices[0].nextMileage").value(15000));

        mvc.perform(post("/api/records")
                        .contentType(MediaType.APPLICATION_JSON).content("{\"title\":\"\"}"))
                .andExpect(status().isBadRequest());

        mvc.perform(delete("/api/records/1"))
                .andExpect(status().isNoContent());

        mvc.perform(get("/api/records/1"))
                .andExpect(status().isNotFound());
    }
}
