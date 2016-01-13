package com.example;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

import ratpack.handling.Handler;
import ratpack.spring.config.EnableRatpack;

/**
 * @author Dave Syer
 *
 */
@SpringBootApplication
@EnableRatpack
public class RatpackApplication {
	
	@Bean
	public Handler handler() {
		return context -> context.render("Hello World!");
	}

	public static void main(String[] args) {
		SpringApplication.run(RatpackApplication.class, args);
	}
}
