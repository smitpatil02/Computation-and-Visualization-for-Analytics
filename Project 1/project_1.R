#IE 6600, Project 1
#Name: Smit Patil
#Section: 03

### Importing Librarires ###
library(dplyr)
library(tidyverse)
library(lubridate)
library(data.table)
library(ggplot2)
library(ggmap)
library(maps)
library(mapdata)
library(datetime)
library(stringr)


fmarket <- read.csv("fmarket.csv")
setDT(fmarket)

year <- fmarket[, .(updateTime)]
year <- as.data.table(sapply(year,gsub,pattern="AM",replacement=""))
year <- as.data.table(sapply(year,gsub,pattern="PM",replacement=""))
new_fmarket <- fmarket[,FMID:SNAP]
new_fmarket <- cbind(new_fmarket, year)

fm_year1 <- new_fmarket[updateTime==2009|updateTime==2011|updateTime==2013,][order(updateTime)]
#fm_year1$updateTime <- years(fm_year1$updateTime)
#fm_year1$updateTime <- as.datetime(as.character(fm_year1$updateTime), format = "%Y")
#fm_year1$updateTime <- as.POSIXct(fm_year1$updateTime)

select_fm_year1 <- with(new_fmarket, which(updateTime==2009|updateTime==2011|updateTime==2013, arr.ind = TRUE))
fm_year2 <- new_fmarket[-select_fm_year1, ][order(updateTime)][1:6191]
fm_year2$updateTime <- mdy_hms(fm_year2$updateTime)

fm_year3 <- new_fmarket[-select_fm_year1, ][order(updateTime)][6192:6485]
fm_year3$updateTime <- mdy_hms(fm_year3$updateTime)
new_table <- rbind(fm_year2,fm_year3)

year1 <- as.data.table(fm_year1[, as.integer(fm_year1$updateTime)])
year2 <- as.data.table(year(new_table$updateTime))
years <- rbind(year1,year2)
new_fmarket <- cbind(new_fmarket,years)
glimpse(new_fmarket)
year_count <- new_fmarket[, .(count = .N), by = V1][order(V1)]

ggplot(data = year_count, aes(x = factor(V1), y = count)) + 
  geom_bar(stat="identity", fill = alpha("#3690ff", 0.7)) + theme_minimal() +
  labs(x = "Year", y = "Number of Markets") + 
  theme_minimal() +
  coord_polar(start = 0) +
  ylim(-500, 1559) +
  theme_minimal() +
  theme(axis.title = element_blank())
  
  

year_growth <- year_count[, (count)]
year_growth <- as.numeric(year_growth)

for (i in 2:length(year_growth)) 
  {
  year_growth[i] = year_growth[i] + year_growth[i-1]
}

yoy_growth <- data.table(year = c('2009', '2011', '2012', '2013', '2014', '2015', '2016', '2017', '2018', '2019', '2020'), yoy_count = year_growth)

ggplot(yoy_growth, aes(x = year, y = yoy_count, group = 1)) +
  geom_line(aes(colour = "#778fed"), size = 1.5) + 
  geom_point(aes(colour = "#778fed"), size = 3) + 
  labs( title = "Year Over Year Growth of United States Farmer Market's", x = "Year", y = "Number of Farmer Market's") +
  theme_minimal() + 
  theme(legend.position = "none")

#################### PIE CHART ####################
online_presence_NA <- fmarket[Website == "", Website := NA][Facebook == "", Facebook := NA][Twitter == "", Twitter := NA][Youtube == "", Youtube := NA][OtherMedia == "", OtherMedia := NA]

op_count <- data.table("Website" = count(na.omit(online_presence_NA, cols = "Website")), 
                "Facebook" = count(na.omit(online_presence_NA, cols = "Facebook")), 
                "Twitter" = count(na.omit(online_presence_NA, cols = "Twitter")), 
                "Youtube" = count(na.omit(online_presence_NA, cols = "Youtube")),
                "OtherMedia" = count(na.omit(online_presence_NA, cols = "OtherMedia")))
op_transpose <- transpose(op_count)
op_names <- data.table("online_presence" = c("Website", "Facebook", "Twitter", "Youtube", "Other Media"))
op <- cbind(op_names, op_transpose) %>%
  mutate(per=`V1`/sum(`V1`)) %>%
  arrange(desc(online_presence))
op$online_presence <- factor(op$online_presence, levels = c("Website", "Facebook", "Twitter", "Youtube", "Other Media"))

ggplot(as.data.frame(op), aes(x="", y=per, fill= online_presence)) +
  geom_bar(stat="identity", width=1, color="white") +
  coord_polar("y", start=0) +
  theme_void() + labs(fill = "Online Presence") +
  scale_fill_manual(values = c("Facebook" = "deepskyblue1",
                               "Website" = "yellow4",
                               "Twitter" = "mediumaquamarine",
                               "Youtube" = "coral2",
                               "Other Media" = "orchid2"))
#+ geom_text(aes(x=1, y = cumsum(per) - per/2, label = label)))

#################### Maps ####################
#Some more libraries
library(sf)
library(tmap)
library(tmaptools)
library(leaflet)
library(geojsonio)
library(broom)
library(maps)
library(ggmap)
library(mapproj)

us_states <- map_data("state")
#head(us_states)
state_count <- fmarket[, .(Count = .N), by = State][order(-Count)]
state_count$region <- tolower(state_count$State)
us_fmarket <- left_join(us_states, state_count)
#head(us_fmarket)

#Chloropleth
ggplot(data = us_fmarket,aes(x = long, y = lat, group = group, fill = Count)) + 
  geom_polygon(color = "gray90", size = 0.1) +
  coord_map(projection = "albers", lat0 = 39, lat1 = 45) +
  scale_fill_gradient(low = "#56B1F7", high = "#132B43") +
  theme_minimal() + xlab("Longitude") + ylab("Latitude") +
  ggtitle("Concentartion of Farmer Markets in US States") +
  theme(panel.grid.major = element_line(color = gray(.5), linetype = "dashed", size = 0.1), panel.background = element_rect(fill = "aliceblue"))

#Dot projection
ggplot() + 
  geom_polygon(data = us_states, aes(x = long, y = lat, group = group), colour = "#AAAAAA" , fill = "#ffffff") +
  coord_map(projection = "albers", lat0 = 39, lat1 = 45) +
  geom_point(data = fmarket, aes(x = x, y = y), colour = "#205527", size = 0.01) +
  xlim(-130, -70) + ylim(25, 50) +
  theme_minimal() + xlab("Longitude") + ylab("Latitude") +
  ggtitle("Distibution of US Farmer Markets") +
  theme(panel.grid.major = element_line(color = "#AAAAAA", linetype = "dashed", size = 0.1), panel.background = element_rect(fill = "#F9FFF9"))

#Watercolour map
devtools::install_github("dkahle/ggmap")
myMap <- get_stamenmap(bbox = c(left = -130,
                                bottom = 25,
                                right = -70,
                                top = 50),
                       maptype = "watercolor", 
                       crop = FALSE,
                       zoom = 4) 
ggmap(myMap) +
  geom_point(data = fmarket, aes(x = x, y = y), colour = "#63322a", size = 0.75) +
  xlab("Longitude") + ylab("Latitude") +
  ggtitle("Distibution of US Farmer Markets")

#Extra dot projection
lat_long <- fmarket[, .(x,y)]
map(database = "state")
symbols(lat_long$x, lat_long$y, circles = rep(1, length(lat_long$x)), inches = 0.01, add = TRUE)
map(database = "state", col = "#cccccc")
symbols(lat_long$x, lat_long$y, bg="#A81612", fg="#ffffff", lwd=0.5, circles = rep(1, length(lat_long$x)), inches = 0.01, add = TRUE) +
  labs(x = "Longitude")

#################### PAYMENT SYSTEM ####################

payment_system_NA <- fmarket[Credit == "N", Credit := NA][WIC == "N", WIC := NA][WICcash == "N", WICcash := NA][SFMNP == "N", SFMNP := NA][SNAP == "N", SNAP := NA]
psna <- new_fmarket[Credit == "N", Credit := NA][WIC == "N", WIC := NA][WICcash == "N", WICcash := NA][SFMNP == "N", SFMNP := NA][SNAP == "N", SNAP := NA]
psna <- new_fmarket[Credit == "Y", Credit := 1][WIC == "Y", WIC := 1][WICcash == "Y", WICcash := 1][SFMNP == "Y", SFMNP := 1][SNAP == "Y", SNAP := 1]
pc <- psna[, .(count = .N, Credit = sum(Credit)), by = V1]
ps_count <- data.table("Credit" = count(na.omit(payment_system_NA, cols = "Credit")), 
                  "WIC" = count(na.omit(payment_system_NA, cols = "WIC")), 
                  "WICcash" = count(na.omit(payment_system_NA, cols = "WICcash")), 
                  "SFMNP" = count(na.omit(payment_system_NA, cols = "SFMNP")),
                  "SNAP" = count(na.omit(payment_system_NA, cols = "SNAP")))

ps_transpose <- transpose(ps_count)
ps_names <- data.table("pay_mode" = c("Credit", "WIC", "WICcash", "SFMNP", "SNAP"))
ps <- cbind(ps_names, ps_transpose)

ggplot(data = ps, aes(x = reorder(pay_mode, -V1), y = V1)) + 
  geom_bar(stat="identity", fill = "#008200") + theme_minimal() +
  labs(x = "Payment Mode", y = "Number of Markets")

#################### Waffle Chart ####################
#Even more libraries
library(qdapTools)
library(waffle)
library(ggthemes)

prod <- fmarket[, Organic:WildHarvested]
prod_count <- mtabulate(prod)
setDT(prod_count)

# 1.) Pantry Waffle Chart
prod_pantry <- prod_count[c(2,10:12,23), Y]
prod_pantry <- as.numeric(prod_pantry)
prod_pantry_names <- sprintf("%s (%s)", c("Baked Goods","Honey","Jam","Maple Syrup","Beans"), scales::percent(round(prod_pantry/sum(prod_pantry), 2)))
names(prod_pantry) <- prod_pantry_names
waffle(prod_pantry/100, rows = 7)

# 2.) Produce Waffle Cahrt
prod_produce <- prod_count[c(1,8,9,24,27,30) ,Y]
prod_produce <- as.numeric(prod_produce)
prod_produce_names <- sprintf("%s (%s)", c("Organic","Herbs","Vegetables","Fruits","Mushrooms","Wild Harvest"), scales::percent(round(prod_produce/sum(prod_produce), 2)))
names(prod_produce) <- prod_produce_names
waffle(prod_produce/100, rows = 9)

# 3.) Dairy Waffle Chart
prod_dairy <- prod_count[c(3,6,29), Y]
prod_dairy <- as.numeric(prod_dairy)
prod_dairy_names <- sprintf("%s (%s)", c("Cheese","Eggs","Tofu"), scales::percent(round(prod_dairy/sum(prod_dairy), 2)))
names(prod_dairy) <- prod_dairy_names
waffle(prod_dairy/100, rows = 5)

# 4.) Meat Waffle Chart
prod_meat <- prod_count[c(7,13,17), Y]
prod_meat <- as.numeric(prod_meat)
prod_meat_names <- sprintf("%s (%s)", c("Sea Food","Meat","Poultry"), scales::percent(round(prod_meat/sum(prod_meat), 2)))
names(prod_meat) <- prod_meat_names
waffle(prod_meat/100, rows = 5)

# 5.) Beverages Waffle Chart
prod_beverage <- prod_count[c(21,22,26), Y]
prod_beverage <- as.numeric(prod_beverage)
prod_beverage_names <- sprintf("%s (%s)", c("Wine","Coffee","Juices"), scales::percent(round(prod_beverage/sum(prod_beverage), 2)))
names(prod_beverage) <- prod_beverage_names
waffle(prod_beverage/100, rows = 3)

# 6.) Nursery Waffle Chart
prod_nursery <- prod_count[c(5,16,20,14), Y]
prod_nursery <- as.numeric(prod_nursery)
prod_nursery_names <- sprintf("%s (%s)", c("Flowers","Plants","Trees","Nursery"), scales::percent(round(prod_nursery/sum(prod_nursery), 2)))
names(prod_nursery) <- prod_nursery_names
waffle(prod_nursery/100, rows = 5)

