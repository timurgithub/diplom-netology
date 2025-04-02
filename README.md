# Дипломная работа - `Акаев Тимур`

## Задача

Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в Yandex Cloud и отвечать минимальным стандартам безопасности

Разработать отказоустойчивую инфраструктуру для статического сайта в Yandex Cloud с использованием **Terraform** и **Ansible**. Реализовать:

- Мониторинг с помощью **Zabbix**
- Сбор логов через **ELK (Elasticsearch + Kibana + Filebeat)**
- Резервное копирование (snapshot дисков)
- Безопасное и централизованное управление через **Bastion-host**

---

## Используемые технологии

- **Terraform** — автоматизация развёртывания инфраструктуры
- **Ansible** — автоматизация настройки ПО на серверах
- **Yandex Cloud** — облачная платформа
- **Zabbix** — мониторинг
- **Elasticsearch**, **Kibana**, **Filebeat** — сбор и визуализация логов
- **Security Groups**, **NAT**, **VPC** — безопасность и сетевая изоляция

---

## Структура проекта

```bash
diplom-infra/
├── ansible/                    # Плейбуки Ansible
│   ├── elk_ansible/
│   │   ├── elasticsearch/
│   │   │   └── main.yml
│   │   ├── filebeat/
│   │   │   └── main.yml
│   │   ├── kibana/
│   │   │   └── main.yml
│   │   └── elk_install.yml
│   ├── install_nginx.yml
│   └── install_zabbix_agent.yml
├── terraform/                  # Код Terraform
│   ├── main.tf
│   ├── provider.tf
│   └── variables.tf
├── .gitignore
├── .terraform.lock.hcl
└── README.md
```

## Полный текст работы в Google Docs

https://docs.google.com/document/d/1esf34VHmL8Bdxd1EuHbXghTOgP6ONVHZ/edit?usp=sharing&ouid=108226062554087059711&rtpof=true&sd=true
