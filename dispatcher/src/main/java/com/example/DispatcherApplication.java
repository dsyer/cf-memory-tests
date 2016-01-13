package com.example;

import java.util.Arrays;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.web.ServerProperties;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.codec.support.ByteBufferEncoder;
import org.springframework.core.codec.support.JacksonJsonEncoder;
import org.springframework.core.codec.support.JsonObjectEncoder;
import org.springframework.core.codec.support.StringEncoder;
import org.springframework.core.convert.ConversionService;
import org.springframework.core.convert.support.GenericConversionService;
import org.springframework.core.convert.support.ReactiveStreamsToCompletableFutureConverter;
import org.springframework.core.convert.support.ReactiveStreamsToReactorStreamConverter;
import org.springframework.core.convert.support.ReactiveStreamsToRxJava1Converter;
import org.springframework.http.server.reactive.boot.RxNettyHttpServer;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.reactive.DispatcherHandler;
import org.springframework.web.reactive.handler.SimpleHandlerResultHandler;
import org.springframework.web.reactive.method.annotation.RequestMappingHandlerAdapter;
import org.springframework.web.reactive.method.annotation.RequestMappingHandlerMapping;
import org.springframework.web.reactive.method.annotation.ResponseBodyResultHandler;
import org.springframework.web.server.WebHandler;
import org.springframework.web.server.WebToHttpHandlerBuilder;

@SpringBootApplication
@EnableConfigurationProperties(ServerProperties.class)
@RestController
public class DispatcherApplication {

	@Autowired
	ServerProperties props;

	@Bean
	public ApplicationRunner starter(final WebHandler webHandler) throws Exception {
		return args -> {
			RxNettyHttpServer server = new RxNettyHttpServer();
			Integer port = this.props.getPort() == null ? 8080 : this.props.getPort();
			server.setPort(port);
			server.setHandler(WebToHttpHandlerBuilder.webHandler(webHandler).build());
			server.afterPropertiesSet();
			Thread thread = new Thread("local-non-daemon") {
				@Override
				public void run() {
					while(server.isRunning()) {
						try {
							Thread.sleep(500l);
						}
						catch (InterruptedException e) {
							// continue
						}
					}
				}
			};
			thread.setDaemon(false);
			thread.start();
			server.start();
		};
	}

	@Bean
	public DispatcherHandler dispatcherHandler() {
		return new DispatcherHandler();
	}

	@RequestMapping("/")
	@ResponseBody
	public String handle() {
		return "Hello World";
	}

	public static void main(String[] args) throws Exception {
		SpringApplication.run(DispatcherApplication.class, args);
	}

	@Configuration
	protected static class FrameworkConfig {

		@Bean
		public RequestMappingHandlerMapping handlerMapping() {
			return new RequestMappingHandlerMapping();
		}

		@Bean
		public RequestMappingHandlerAdapter handlerAdapter() {
			RequestMappingHandlerAdapter handlerAdapter = new RequestMappingHandlerAdapter();
			handlerAdapter.setConversionService(conversionService());
			return handlerAdapter;
		}

		@Bean
		public ConversionService conversionService() {
			GenericConversionService service = new GenericConversionService();
			service.addConverter(new ReactiveStreamsToCompletableFutureConverter());
			service.addConverter(new ReactiveStreamsToReactorStreamConverter());
			service.addConverter(new ReactiveStreamsToRxJava1Converter());
			return service;
		}

		@Bean
		public ResponseBodyResultHandler responseBodyResultHandler() {
			return new ResponseBodyResultHandler(Arrays.asList(
					new ByteBufferEncoder(), new StringEncoder(), new JacksonJsonEncoder(new JsonObjectEncoder())),
					conversionService());
		}

		@Bean
		public SimpleHandlerResultHandler simpleHandlerResultHandler() {
			return new SimpleHandlerResultHandler(conversionService());
		}

	}

}