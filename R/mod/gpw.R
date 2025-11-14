box::use(httr[...],
         jsonlite[...],
         xts[...],
         zoo[...],
         rvest[...],
         dplyr[...],
         tidyr = tidyr[separate],
         purrr = purrr[map, slowly, rate_delay],
         readr = readr[read_csv],
         janitor = janitor[clean_names],
         sjmisc = sjmisc[rotate_df],
         stats = stats[na.omit],
         stringr = stringr[str_remove_all],
         readr = readr[parse_number]
)




#' 
stooq_dw <- function(symbol, close_only = TRUE){
  
  s_link <- "https://stooq.pl/q/d/l/?s="
  s_symbol <- symbol
  s_end <- "&i=d"
  
  full_link <- paste0(s_link, s_symbol, s_end)
  
  my_data <- read_csv(full_link)
  my_data <- my_data %>% dplyr::select(Data,Otwarcie,Najwyzszy,Najnizszy,Zamkniecie)
  colnames(my_data) <- c("Date", "Open", "High", "Low", "Close")
  my_data <- na.locf(my_data)
  
  if(close_only == TRUE){
    my_data <- my_data %>% dplyr::select(Date, Close) %>% rename_with(~ gsub("[^[:alnum:] ]", "", s_symbol), .cols = Close)
    
    
    
  }else{
    my_data
  }
  
  
  
}



#' @export
get_stooq_data <- function(ticks){
  
  
  xy <- map(ticks, stooq_dw)
  
  
  
  W20 <- read_csv("https://stooq.pl/q/d/l/?s=wig&i=d")
 
  
  
  
  master_t <- tibble(Date = W20$Data)
  
  for(n in seq_along(xy)){
    print(n)
    master_t <- master_t %>% left_join(xy[[n]], by = "Date")
    
    
  }
  master_t
  
}


#' @export
get_table <- function(table_url){
  
  table_path <- '//*[@id="profile-finreports"]/table'
  
  set_config(add_headers(`User-Agent` = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Safari/537.36"))
  
  get_delayed <- slowly(~ GET(.), 
                        rate = rate_delay(3))
  
  get_result <- get_delayed(table_url)
  
  raw_html <- read_html(get_result)
  
  Sys.sleep(3)
  raw_html %>% html_nodes(xpath = table_path) %>% 
    html_table()
  
}


#' @export
get_companies <- function(table_url){
  
  table_path <- '//*[@id="right-content"]/div/table'
  
  set_config(add_headers(`User-Agent` = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Safari/537.36"))
  
  get_delayed <- slowly(~ GET(.), 
                        rate = rate_delay(3))
  
  get_result <- get_delayed(table_url)
  
  raw_html <- read_html(get_result)
  
  raw_html %>% html_nodes(xpath = table_path) %>% 
    html_table()
  
}

#' @export
get_companies2 <- function(table_url){
  
  table_path <- '//*[@id="main-props"]/div/main/div/div[3]/table'
  
  set_config(add_headers(`User-Agent` = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Safari/537.36"))
  
  get_delayed <- slowly(~ GET(.), 
                        rate = rate_delay(3))
  
  get_result <- get_delayed(table_url)
  
  raw_html <- read_html(get_result)
  
  raw_html %>% html_nodes(xpath = table_path) %>% 
    html_table()
  
}




#' @export
get_companies_links <- function(table_url){
  
  table_path <- '//*[@id="right-content"]/div/table'
  
  set_config(add_headers(`User-Agent` = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Safari/537.36"))
  
  get_delayed <- slowly(~ GET(.), 
                        rate = rate_delay(3))
  
  get_result <- get_delayed(table_url)
  
  raw_html <- read_html(get_result)
  
  companies <- raw_html |> html_elements(xpath = table_path) |> html_table()
  companies <- companies[[1]] |> clean_names() |>
    separate(col = profil, into = c("ticker", "name"), sep = " ") |> select(ticker) |> 
    filter(nchar(ticker) == 3)
  
  c_links <- tibble(link = paste0("https://www.biznesradar.pl", 
                                  raw_html |> html_elements(xpath = table_path)  |> 
                      html_elements(".bvalue") |> html_elements("a") |> html_attr("href"),
           ",", "Q"))
  
  c_links <- c_links |> filter(link != "https://www.biznesradar.pl/raporty-finansowe-rachunek-zyskow-i-strat/SVRS,Q")

  companies$link <- c_links$link
  companies
  
}


#' @export
get_companies_links_bilans <- function(table_url){
  
  table_path <- '//*[@id="right-content"]/div/table'
  
  set_config(add_headers(`User-Agent` = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Safari/537.36"))
  
  get_delayed <- slowly(~ GET(.), 
                        rate = rate_delay(3))
  
  get_result <- get_delayed(table_url)
  
  raw_html <- read_html(get_result)
  
  companies <- raw_html |> html_elements(xpath = table_path) |> html_table()
  companies <- companies[[1]] |> clean_names() |>
    separate(col = profil, into = c("ticker", "name"), sep = " ") |> select(ticker) |> 
    filter(nchar(ticker) == 3)
  
  c_links <- tibble(link = paste0("https://www.biznesradar.pl", 
                                  raw_html |> html_elements(xpath = table_path)  |> 
                                    html_elements(".bvalue") |> html_elements("a") |> html_attr("href"),
                                  ",", "Q"))
  
  c_links <- c_links |> filter(link != "https://www.biznesradar.pl/raporty-finansowe-bilans/SVRS,Q")
  
  companies$link <- c_links$link
  companies
  
}



#' @export
get_companies_links_cf <- function(table_url){
  
  table_path <- '//*[@id="right-content"]/div/table'
  
  set_config(add_headers(`User-Agent` = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Safari/537.36"))
  
  get_delayed <- slowly(~ GET(.), 
                        rate = rate_delay(3))
  
  get_result <- get_delayed(table_url)
  
  raw_html <- read_html(get_result)
  
  companies <- raw_html |> html_elements(xpath = table_path) |> html_table()
  companies <- companies[[1]] |> clean_names() |>
    separate(col = profil, into = c("ticker", "name"), sep = " ") |> select(ticker) |> 
    filter(nchar(ticker) == 3)
  
  c_links <- tibble(link = paste0("https://www.biznesradar.pl", 
                                  raw_html |> html_elements(xpath = table_path)  |> 
                                    html_elements(".bvalue") |> html_elements("a") |> html_attr("href"),
                                  ",", "Q"))
  
  c_links <- c_links |> filter(link != "https://www.biznesradar.pl/raporty-finansowe-przeplywy-pieniezne/SVRS,Q")
  
  companies$link <- c_links$link
  companies
  
}



#' @export
clean_rzis <- function(tb){
  tb |> clean_names() |> rotate_df(cn = TRUE) |> as_tibble(.name_repair = "unique") |> clean_names() |> 
    mutate(data_publikacji = as.Date(data_publikacji)) |>
    mutate(across(przychody_ze_sprzedazy:ebitda, str_remove_all, " ")) |> 
    mutate(across(przychody_ze_sprzedazy:ebitda, parse_number)) 
}


#' @export
clean_bilans <- function(tb){
  tb |> 
    clean_names() |> mutate(x = paste0(x, 1:nrow(tb))) |> 
    rotate_df(cn = TRUE) |> as_tibble() |> clean_names() |> 
    mutate(data_publikacji1 = as.Date(data_publikacji1)) |> 
    mutate(across(aktywa_trwale2:pasywa_razem36, str_remove_all, " ")) |> 
    mutate(across(aktywa_trwale2:pasywa_razem36, parse_number)) |> 
    select(-wartosc_firmy4, -aktywa_z_tytulu_prawa_do_uzytkowania6)  
    
    
    
}

#' @export
clean_cf <- function(tb){
  tb |> 
    clean_names() |> 
    rotate_df(cn = TRUE) |> as_tibble() |> clean_names() |> 
    mutate(data_publikacji = as.Date(data_publikacji)) |> 
    mutate(across(przeplywy_pieniezne_z_dzialalnosci_operacyjnej:free_cash_flow, str_remove_all, " ")) |> 
    mutate(across(przeplywy_pieniezne_z_dzialalnosci_operacyjnej:free_cash_flow, parse_number)) 
  
  
  
}


#' @export
get_companies_links_cv <- function(table_url){
  
  table_path <- '//*[@id="right-content"]/div/table'
  
  set_config(add_headers(`User-Agent` = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Safari/537.36"))
  
  get_delayed <- slowly(~ GET(.), 
                        rate = rate_delay(3))
  
  get_result <- get_delayed(table_url)
  
  raw_html <- read_html(get_result)
  
  companies <- raw_html |> html_elements(xpath = table_path) |> html_table()
  companies <- companies[[1]] |> clean_names() |>
    separate(col = profil, into = c("ticker", "name"), sep = " ") |> select(ticker) |> 
    filter(nchar(ticker) == 3)
  
  c_links <- tibble(link = paste0("https://www.biznesradar.pl", 
                                  raw_html |> html_elements(xpath = table_path)  |> 
                                    html_elements(".bvalue") |> html_elements("a") |> html_attr("href")))
  
  c_links <- c_links |> filter(link != "https://www.biznesradar.pl/wskazniki-wartosci-rynkowej/SVRS")
  
  companies$link <- c_links$link
  companies
  
}



#' @export
clean_cv <- function(tb){
  
  tb |> 
    clean_names() |> names() -> col_names
  
  col_names_ok <- col_names[2:(length(col_names)-1)]
  
  tmp <- tb |> 
    clean_names() |> 
    rotate_df(cn = TRUE) |> as_tibble() |> clean_names()
  tmp <- tmp[-nrow(tmp),]
  
  tmp <- tmp |> mutate(okres = col_names_ok) |> select(liczba_akcji, okres) |> 
    mutate(okres = str_remove_all(okres, "x")) |> 
    separate(col = okres, into = c("rok", "kwartal", "mies", "rok_skr")) |> 
    mutate(rok = as.numeric(rok)) |> 
    mutate(kwartal = as.numeric(str_remove_all(kwartal, "q"))) |> 
    select(-mies, -rok_skr) |> 
    mutate(liczba_akcji = str_remove_all(liczba_akcji, " ")) |> 
    mutate(liczba_akcji = parse_number(liczba_akcji))
  
  tmp
  
}





