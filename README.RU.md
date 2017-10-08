# pushall.sh

Реализация [API pushall.ru](https://pushall.ru/blog/api) на POSIX-совместимом Shell-script.

v. 0.1.1-alpha  
[![Build Status](https://travis-ci.org/nibb13/pushall.sh.svg?branch=develop)](https://travis-ci.org/nibb13/pushall.sh)

## Функциональность

* Self API
* Очередь отправки

## Требования

* POSIX shell (протестировано на busybox/ash)
* sed
* awk (awk / gawk / mawk)
* grep
* date
* curl

## Установка

Положите куда-нибудь pushall.sh и JSON.awk, далее выполните:

	chmod +x pushall.sh
	chmod +x JSON.awk

Готово.

Скрипт зависит от пользователя, от которого запускается. Ваша очередь не будет пересекаться с очередью другого пользователя.
Скрипт использует `$XDG_DATA_HOME` для хранения очереди. Если не задана, то по-умолчанию: `~/.local/share`

## Использование

**Простая отправка с использованием self API**  
*(Не рекомендуется, используйте вместо этого queue)*

`./pushall.sh -c self -t "Title" -T "Text" -u "http://yourdomain.com/messagetargeturl" -I "pushall_id" -K "pushall_key"`  
*(Вернёт LID или сообщение об ошибке от API)*

**Добавление сообщения через self API в конец очереди**

`./pushall.sh -c self -t "Title" -T "Text" -u "http://yourdomain.com/messagetargeturl" -I "pushall_id" -K "pushall_key" queue`  
*(Вернёт уникальный ID сообщения в очереди)*

**Добавление сообщения через self API в начало очереди**

`./pushall.sh -c self -t "Title" -T "Text" -u "http://yourdomain.com/messagetargeturl" -I "pushall_id" -K "pushall_key" queue top`  
*(Вернёт уникальный ID сообщения в очереди)*

**Выполнение существующей очереди с соблюдением тайм-аутов API**

`./pushall.sh run`  
*(Вернёт список LID'ов или сообщения об ошибках API)*

**Удаление одного сообщения из очереди**

`./pushall.sh delete <ID>`  
*(Используйте ID, который вернул вызов `queue` или `queue top`)*

**Полная очистка очереди**

`./pushall.sh clear`

## Известные проблемы и ограничения

* Все используемые блокировки общесистемные, в то время как очереди - нет (Issue [#12](https://github.com/nibb13/pushall.sh/issues/12))

## Бенчмарки

*Сделаем, если на то будет необходимость*

## Требуется помощь

Все замечания, предложения, пулл-реквесты, багрепорты, отчёты об использовании и т.д. горячо приветствуются и оцениваются по достоинству. Серьёзно.

## Благодарности

Экипажу [PushAll](https://pushall.ru) за крутой сервис.  
[D-Link](http://dlink.com) за превосходное оборудование.  
[step-](https://github.com/step-) за [JSON.awk](https://github.com/step-/JSON.awk).

## Для связи

<nibble@list.ru>  

Last update: 08.10.2017
