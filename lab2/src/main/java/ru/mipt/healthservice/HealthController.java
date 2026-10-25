package ru.mipt.healthservice;

import java.util.Map;
import java.util.HashMap;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {

    @GetMapping("/health")
    public Map<String, String> health() {
        HashMap<String, String> response = new HashMap<>();
        response.put("status", "UP");
        response.put("github", "Iwillfinduo");
        return response;
    }
}
