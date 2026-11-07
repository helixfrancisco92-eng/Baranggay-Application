package com.ibarangay;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.Properties;

@SpringBootApplication
public class IbaranggayApplication {

	private static final Logger logger = LoggerFactory.getLogger(IbaranggayApplication.class);

	public static void main(String[] args) {
		autoCreateDatabaseIfNotExists();
		SpringApplication.run(IbaranggayApplication.class, args);
	}

	/**
	 * Automatically creates the target PostgreSQL database if it does not exist yet.
	 * This ensures the application runs out-of-the-box on any student's machine
	 * without requiring manual database creation in pgAdmin or psql.
	 */
	private static void autoCreateDatabaseIfNotExists() {
		try {
			Properties envProps = new Properties();
			java.io.File dotEnv = new java.io.File(".env");
			if (dotEnv.exists()) {
				try (java.io.FileInputStream fis = new java.io.FileInputStream(dotEnv)) {
					envProps.load(fis);
				}
			}

			Properties props = new Properties();
			try (InputStream in = IbaranggayApplication.class.getClassLoader().getResourceAsStream("application.properties")) {
				if (in != null) {
					props.load(in);
				}
			}

			String url = resolveVal("DB_URL", props.getProperty("spring.datasource.url"), envProps, "jdbc:postgresql://localhost:5432/PPGG_projectdb");
			String user = resolveVal("DB_USER", props.getProperty("spring.datasource.username"), envProps, "postgres");
			String password = resolveVal("DB_PASSWORD", props.getProperty("spring.datasource.password"), envProps, "postgres");

			if (url == null || !url.startsWith("jdbc:postgresql://")) {
				return;
			}

			// Parse base URL and target database name
			int lastSlash = url.lastIndexOf('/');
			if (lastSlash == -1) {
				return;
			}
			int questionMark = url.indexOf('?', lastSlash);
			String targetDb = questionMark != -1 ? url.substring(lastSlash + 1, questionMark) : url.substring(lastSlash + 1);
			String baseUrl = url.substring(0, lastSlash + 1);

			// Connect to default PostgreSQL maintenance database 'postgres'
			String maintenanceUrl = baseUrl + "postgres";

			logger.info("Checking if database '{}' exists...", targetDb);
			try (Connection conn = DriverManager.getConnection(maintenanceUrl, user, password);
				 Statement stmt = conn.createStatement()) {

				String checkSql = "SELECT 1 FROM pg_database WHERE datname = '" + targetDb + "'";
				try (ResultSet rs = stmt.executeQuery(checkSql)) {
					if (!rs.next()) {
						logger.info("Database '{}' does not exist. Creating it automatically...", targetDb);
						stmt.executeUpdate("CREATE DATABASE \"" + targetDb + "\"");
						logger.info("Database '{}' created successfully!", targetDb);
					} else {
						logger.info("Database '{}' verified and exists.", targetDb);
					}
				}
			}
		} catch (Exception e) {
			logger.warn("Auto-database check warning: {}. Continuing with Spring Boot startup...", e.getMessage());
		}
	}

	private static String resolveVal(String envKey, String propVal, Properties envProps, String fallback) {
		String val = System.getenv(envKey);
		if (val != null && !val.isBlank()) return val;
		val = envProps.getProperty(envKey);
		if (val != null && !val.isBlank()) return val;
		if (propVal != null) {
			if (propVal.startsWith("${") && propVal.endsWith("}")) {
				String inner = propVal.substring(2, propVal.length() - 1);
				int colon = inner.indexOf(':');
				String envName = colon != -1 ? inner.substring(0, colon) : inner;
				String defVal = colon != -1 ? inner.substring(colon + 1) : "";
				String envVal = System.getenv(envName);
				if (envVal != null && !envVal.isBlank()) return envVal;
				String envFileVal = envProps.getProperty(envName);
				if (envFileVal != null && !envFileVal.isBlank()) return envFileVal;
				return defVal;
			}
			return propVal;
		}
		return fallback;
	}
}
