package com.example;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class DispatcherApplication {

	@RequestMapping("/")
	@ResponseBody
	public String handle() {
		return "Hello World";
	}

	public static void main(String[] args) throws Exception {
		SpringApplication.run(DispatcherApplication.class, args);
	}

}