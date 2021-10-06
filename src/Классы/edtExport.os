#Использовать logos
#Использовать csv
#Использовать v8metadata-reader

Перем _Лог;
Перем _РезультатПроверки;
Перем _ФайлДжсон;
Перем _КаталогИсходников;
Перем _ВыгружатьОшибкиОбъектов;

Перем ГенераторПутей;

Процедура ОписаниеКоманды(Команда) Экспорт
	
	Команда.Аргумент("EDT_VALIDATION_RESULT", "", "Путь к файлу с результатом проверки edt. Например ./edt-result.out")
	.ТСтрока()
	.ВОкружении("EDT_VALIDATION_RESULT");
	
	Команда.Аргумент("EDT_VALIDATION_JSON", "", "Путь к файлу результату. Например ./edt-json.json")
	.ТСтрока()
	.ВОкружении("EDT_VALIDATION_JSON");
	
	Команда.Аргумент("SRC", "", "Путь к каталогу с исходниками. Например ./src")
	.ТСтрока()
	.ВОкружении("SRC");
	
	Команда.Опция("e ObjectErrors", Ложь, "Ошибки объектов назначать на первую строку модуля формы/объекта");
	
КонецПроцедуры

Процедура ВыполнитьКоманду(Знач Команда) Экспорт
	
	ИнициализацияПараметров(Команда);
	
	таблицаРезультатов = ТаблицаПоФайлуРезультата();
	
	ЗаполнитьВТаблицеРезультатовИсходныеПути(таблицаРезультатов);
	ЗаполнитьВТаблицеРезультатовНомераСтрок(таблицаРезультатов);
	
	записьВДжсон = Новый ЗаписьReportJSON(_ФайлДжсон, _Лог);
	записьВДжсон.Записать(таблицаРезультатов);
	
КонецПроцедуры

Процедура ИнициализацияПараметров(Знач Команда)
	
	результатПроверки = Команда.ЗначениеАргумента("EDT_VALIDATION_RESULT");
	_лог.Отладка("EDT_VALIDATION_RESULT = " + результатПроверки);
	путьКРезультату = Команда.ЗначениеАргумента("EDT_VALIDATION_JSON");
	_лог.Отладка("EDT_VALIDATION_JSON = " + путьКРезультату);
	путьККаталогуИсходников = Команда.ЗначениеАргумента("SRC");
	_лог.Отладка("SRC = " + путьККаталогуИсходников);
	
	_РезультатПроверки = ОбщегоНазначения.АбсолютныйПуть(результатПроверки);
	_лог.Отладка("Файл с результатом проверки EDT = " + _РезультатПроверки);
	
	Если Не ОбщегоНазначения.ФайлСуществует(_РезультатПроверки) Тогда
		
		_лог.Ошибка(СтрШаблон("Файл с результатом проверки <%1> не существует.", результатПроверки));
		ЗавершитьРаботу(1);
		
	КонецЕсли;
	
	_КаталогИсходников = ОбщегоНазначения.АбсолютныйПуть(путьККаталогуИсходников);
	каталогИсходников = Новый Файл(_КаталогИсходников);
	_лог.Отладка("Каталог исходников = " + _КаталогИсходников);
	
	Если Не каталогИсходников.Существует()
		Или Не каталогИсходников.ЭтоКаталог() Тогда
		
		_лог.Ошибка(СтрШаблон("Каталог исходников <%1> не существует.", путьККаталогуИсходников));
		ЗавершитьРаботу(1);
		
	КонецЕсли;
	
	_ФайлДжсон = ОбщегоНазначения.АбсолютныйПуть(путьКРезультату);
	_лог.Отладка("Файл результат = " + _ФайлДжсон);
	
	_ВыгружатьОшибкиОбъектов = Команда.ЗначениеОпции("ObjectErrors");
	
	ГенераторПутей = Новый Путь1СПоМетаданным(_КаталогИсходников);
	
КонецПроцедуры

Функция ТаблицаПоФайлуРезультата()
	
	разделительВФайле = "	";
	кодировкаФайла = КодировкаТекста.UTF8;
	
	_Лог.Отладка("Чтение файла результата %1", _РезультатПроверки);
	
	тз = Новый ТаблицаЗначений;
	тз.Колонки.Добавить("ДатаОбнаружения");
	тз.Колонки.Добавить("Тип");
	тз.Колонки.Добавить("Серьезность");
	тз.Колонки.Добавить("Проект");
	тз.Колонки.Добавить("Правило");
	
	тз.Колонки.Добавить("Метаданные");
	тз.Колонки.Добавить("Положение");
	тз.Колонки.Добавить("Описание");
	
	ЧтениеТекста = Новый ЧтениеТекста(_РезультатПроверки, кодировкаФайла);
	
	данныеФайла = ЧтениеCSV.ИзЧтенияТекста(ЧтениеТекста, разделительВФайле);
	
	ЧтениеТекста.Закрыть();
	
	всегоОшибок = 0;
	
	Если данныеФайла.Количество() = 0 Тогда
		
		_Лог.Информация("Из файла %1 прочитано %2 строк из %3", _РезультатПроверки, данныеФайла.Количество(), всегоОшибок);
		Возврат тз;
		
	КонецЕсли;
	
	именаПолей = ИменаПолей(данныеФайла);
	
	Для каждого цПоля Из данныеФайла Цикл
		
		Если цПоля.Количество() = 0 Тогда
			Продолжить;
		КонецЕсли;
		
		всегоОшибок = всегоОшибок + 1;
		
		положение = цПоля[именаПолей.Положение];
		
		Если Не _ВыгружатьОшибкиОбъектов
			И (Не ЗначениеЗаполнено(положение)
				ИЛИ Не СтрНачинаетсяС(ВРег(положение), "СТРОКА")) Тогда
			
			// Нас интересуют только ошибки в модулях, а у них есть положение.
			Продолжить;
			
		КонецЕсли;
		
		описание = цПоля[именаПолей.Описание];
		
		Если ЗначениеЗаполнено(описание)
			И СтрНачинаетсяС(описание, "[BSL LS]") Тогда
			
			// Пропускаем ошибки от плагина, т.к. BSL-LS отдельно выполняет проверку
			Продолжить;
			
		КонецЕсли;
		
		ДобавитьСтрокуВТаблицу(цПоля, тз, именаПолей);
		
	КонецЦикла;
	
	_Лог.Информация("Из файла %1 прочитано %2 строк из %3", _РезультатПроверки, тз.Количество(), всегоОшибок);
	
	// В отчете могут быть дубли
	
	тз.Свернуть("Правило,Серьезность,Тип,Метаданные,Положение,Описание");
	
	Возврат тз;
	
КонецФункции

Функция ИменаПолей(данныеФайла)
	
	перваяСтрока = данныеФайла[0];
	
	именаПолей = Новый Структура();

	столбцовВ_2021_2 = 8;
	Если перваяСтрока.Количество() = столбцовВ_2021_2 Тогда
		
		// В 2021.2 добавили новую колонку и поменяли порядок
		именаПолей.Вставить("ДатаОбнаружения", 0);
		именаПолей.Вставить("Тип", 1);
		именаПолей.Вставить("Серьезность", 2);
		именаПолей.Вставить("Проект", 3);
		именаПолей.Вставить("Правило", 4);
		именаПолей.Вставить("Метаданные", 5);
		именаПолей.Вставить("Положение", 6);
		именаПолей.Вставить("Описание", 7);
		
	Иначе
		
		именаПолей.Вставить("ДатаОбнаружения", 0);
		именаПолей.Вставить("Тип", 1);
		именаПолей.Вставить("Проект", 2);
		именаПолей.Вставить("Метаданные", 3);
		именаПолей.Вставить("Положение", 4);
		именаПолей.Вставить("Описание", 5);
		
	КонецЕсли;
	
	Возврат именаПолей;
	
КонецФункции

Процедура ДобавитьСтрокуВТаблицу(СтрокаДанных, тз, именаПолей)
	
	новСтрока = тз.Добавить();
	
	Для каждого цКлючИЗначение Из именаПолей Цикл
		
		новСтрока[цКлючИЗначение.Ключ] = СтрокаДанных[цКлючИЗначение.Значение];
		
	КонецЦикла;
	
	Если Не ЗначениеЗаполнено(новСтрока.Серьезность) Тогда
		
		новСтрока.Серьезность = "Ошибка";
		
	КонецЕсли;
	
	ПереопределитьПути(новСтрока);
	
КонецПроцедуры

Процедура ПереопределитьПути(СтрокаТаблицы)
	
	Если Не _ВыгружатьОшибкиОбъектов Тогда
		
		Возврат;
		
	КонецЕсли;
	
	Если СтрНачинаетсяС(ВРег(СтрокаТаблицы.Положение), "СТРОКА") Тогда
		
		Возврат;
		
	КонецЕсли;
	
	мета = СтрокаТаблицы.Метаданные;
	
	Если СтрЗаканчиваетсяНа(ВРег(мета), ".ФОРМА") Тогда
		
		// Вешаем на модуль формы
		
		СтрокаТаблицы.Метаданные = мета + ".Модуль";
		
	ИначеЕсли СтрРазделить(мета, ".").Количество() = 2 Тогда
		
		Если ПутьКМетаданнымСуществует(мета + ".МодульОбъекта") Тогда
			
			СтрокаТаблицы.Метаданные = мета + ".МодульОбъекта";
			
		ИначеЕсли ПутьКМетаданнымСуществует(мета + ".МодульМенеджера") Тогда
			
			СтрокаТаблицы.Метаданные = мета + ".МодульМенеджера";
			
		ИначеЕсли ПутьКМетаданнымСуществует(мета + ".МодульНабораЗаписей") Тогда
			
			СтрокаТаблицы.Метаданные = мета + ".МодульНабораЗаписей";
			
		ИначеЕсли ПутьКМетаданнымСуществует(мета + ".МодульМенеджераЗначения") Тогда
			
			СтрокаТаблицы.Метаданные = мета + ".МодульМенеджераЗначения";
			
		ИначеЕсли ПутьКМетаданнымСуществует(мета + ".МодульКоманды") Тогда
			
			СтрокаТаблицы.Метаданные = мета + ".МодульКоманды";
			
		Иначе
			
			СтрокаТаблицы.Метаданные = "Конфигурация.МодульУправляемогоПриложения";
			СтрокаТаблицы.Описание = мета + ": " + СтрокаТаблицы.Описание;
			
		КонецЕсли;
		
	ИначеЕсли СтрНачинаетсяС(ВРег(мета), "ПОДСИСТЕМА.") Тогда
		
		СтрокаТаблицы.Метаданные = "Конфигурация.МодульУправляемогоПриложения";
		СтрокаТаблицы.Описание = мета + ": " + СтрокаТаблицы.Описание;
		
	Иначе
		
		_Лог.Предупреждение("Не переопределен путь для %1", мета);
		
		СтрокаТаблицы.Метаданные = "Конфигурация.МодульУправляемогоПриложения";
		СтрокаТаблицы.Описание = мета + ": " + СтрокаТаблицы.Описание;
		
	КонецЕсли;
	
	СтрокаТаблицы.Положение = "Строка 1";
	
КонецПроцедуры

Процедура ЗаполнитьВТаблицеРезультатовИсходныеПути(таблицаРезультатов)
	
	таблицаРезультатов.Колонки.Добавить("Путь");
	
	Для каждого цСтрока Из таблицаРезультатов Цикл
		
		цСтрока.Путь = генераторПутей.Путь(цСтрока.Метаданные);
		
		Если Не ПроверитьПуть(цСтрока.Путь, цСтрока.Метаданные) Тогда
			
			цСтрока.Путь = "";
			
		КонецЕсли;
		
	КонецЦикла;
	
	поискСтрокКУдалению = Новый Структура("Путь", "");
	
	Для каждого цСтрокаКУдалению Из таблицаРезультатов.НайтиСтроки(поискСтрокКУдалению) Цикл
		
		таблицаРезультатов.Удалить(цСтрокаКУдалению);
		
	КонецЦикла;
	
КонецПроцедуры

Процедура ЗаполнитьВТаблицеРезультатовНомераСтрок(таблицаРезультатов)
	
	таблицаРезультатов.Колонки.Добавить("НомерСтроки");
	
	Для каждого цСтрока Из таблицаРезультатов Цикл
		
		цСтрока.НомерСтроки = СтрЗаменить(ВРег(цСтрока.Положение), "СТРОКА ", "");
		
	КонецЦикла;
	
КонецПроцедуры

Функция ПутьКМетаданнымСуществует(Знач пМетаданные)
	
	Путь = генераторПутей.Путь(пМетаданные);
	
	Возврат ПроверитьПуть(Путь, пМетаданные, Ложь);
	
КонецФункции

Функция ПроверитьПуть(Знач пПуть, Знач пМетаданные = "", Знач пСообщать = Истина)
	
	Если Не ЗначениеЗаполнено(пПуть) Тогда
		
		Если пСообщать Тогда
			
			_лог.Ошибка(СтрШаблон("Путь для <%1> не получен", пМетаданные));
			
		КонецЕсли;
		
		Возврат Ложь;
		
	ИначеЕсли Не ОбщегоНазначения.ФайлСуществует(пПуть) Тогда
		
		Если пСообщать Тогда
			
			_лог.Ошибка(СтрШаблон("Путь <%1> для <%2> не существует", пПуть, пМетаданные));
			
		КонецЕсли;
		
		Возврат Ложь;
		
	Иначе
		
		Возврат Истина;
		
	КонецЕсли;
	
КонецФункции

Функция ИмяЛога() Экспорт
	
	Возврат "oscript.app." + ОПриложении.Имя();
	
КонецФункции

_Лог = Логирование.ПолучитьЛог(ИмяЛога());