package com.example;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.SpringBootConfiguration;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.autoconfigure.context.ConfigurationPropertiesAutoConfiguration;
import org.springframework.boot.autoconfigure.context.PropertyPlaceholderAutoConfiguration;
import org.springframework.boot.autoconfigure.web.reactive.HttpHandlerAutoConfiguration;
import org.springframework.boot.autoconfigure.web.reactive.ReactiveWebServerFactoryAutoConfiguration;
import org.springframework.boot.autoconfigure.web.reactive.WebFluxAutoConfiguration;
import org.springframework.boot.autoconfigure.web.reactive.error.ErrorWebFluxAutoConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.web.reactive.function.server.RouterFunction;

import static org.springframework.web.reactive.function.server.RequestPredicates.GET;
import static org.springframework.web.reactive.function.server.RouterFunctions.route;
import static org.springframework.web.reactive.function.server.ServerResponse.ok;

import reactor.core.publisher.Mono;

@SpringBootConfiguration
@ImportAutoConfiguration({ PropertyPlaceholderAutoConfiguration.class,
		ConfigurationPropertiesAutoConfiguration.class,
		ReactiveWebServerFactoryAutoConfiguration.class, WebFluxAutoConfiguration.class,
		ErrorWebFluxAutoConfiguration.class, HttpHandlerAutoConfiguration.class })
public class MicroApplication {

	@Value("${app.value:Hello World}")
	private String value;

	@Bean
	public RouterFunction<?> userEndpoints() {
		return route(GET("/"), request -> ok().body(Mono.just(value), String.class));
	}

	public static void main(String[] args) throws Exception {
		SpringApplication.run(MicroApplication.class, args);
	}

}