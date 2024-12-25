
<div align="center">
<img src="https://github.com/user-attachments/assets/4d3beba4-04e2-41e2-8645-0887cbde4b5c" width="240" /> 
</div>

# ggfigdone: Manage ggplot figures using ggfigdone
[![R](https://github.com/wenjie1991/ggfigdone/actions/workflows/r.yml/badge.svg)](https://github.com/wenjie1991/ggfigdone/actions/workflows/r.yml)


## Description

When you prepare a presentation or a report, you often need to manage a large number of ggplot figures. 
You need to change the figure size, modify the title, label, themes, etc. 
It is inconvinient to go back to the original code to make these changes.
This package provides a simple way to manage ggplot figures. 

## Features

### Manage figures

You can easily add the figure to the database and manage it later using CLI (command line interface) or GUI (graphical user interface).

https://github.com/user-attachments/assets/7bcccfdd-e48d-49c7-9c18-ec0c41ee0481



### Update figures by LLM

Utilizing the LLM to convert your natural language idea into {ggplot2} code.

https://github.com/user-attachments/assets/524a6d44-012d-4a55-8a5a-83b44f1ffadd

## Installation

Install the stable version from CRAN:

```r
install.packages("ggfigdone")
```

Install the development version from GitHub:

```r
# install.packages("remotes")
remotes::install_github("wenjie1991/ggfigdone")
```


## Demo

### Initialize the database

First, you need to initialize the database and add figures to it.

Next time, you only need to load the database to add more figures or update the existing figures.


```r
library(ggfigdone)
library(ggplot2)

## Initial ggfigdone database using `fd_init`
## The database location is `./fd_dir`
## Load existing database using `fd_load("./fd_dir")`
fo = fd_init("./fd_dir")

## Draw a ggplot figure
g = ggplot(mtcars, aes(x=wt, y=mpg)) + geom_point()

## Add the figure to the database
## The last plot is added to the last initialized/loaded database
fd_add(name  = "fig1")

## Add the same figure with a different name
## You can specify the ggplot object and database name
fd_add(g = g, name  = "fig2", fo)

## The hard disk database is automatically updated, no need to save operations.
```

### Manage the figures in browser

Then you can start the server and open the browser to manage the figures.

```r
## To start the server, provide the database location 
fd_server("./fd_dir")

## Open the browser and go to http://localhost:8080/index.html
```

## Configure LLM Service

### LLM API key

**OpenAI API**


Please visit the OpenAI website at https://openai.com/ and follow the instructions in the video. You may need to update your payment methods.

https://github.com/user-attachments/assets/e5fc4feb-5dc4-4473-826d-ec69b5c0d9a5


**Free API key**


You can access a free LLM service at this link: https://github.com/cheahjs/free-llm-api-resources

The following video demonstrates how to apply the GroqCloud key for free.

Link: https://console.groq.com/login


https://github.com/user-attachments/assets/5624798a-1c86-4694-b7a0-69daaacf470f


### Configure {ggfigdone}


**Example: OpenAI service**

The default configuration is the OpenAI service, where you only need to provide the OpenAI API key.

```r
fd_server("./fd_dir", 
    llm_api_key = "sk-use_your_own_key_here"),
)
```

**Example: Groq service**

To use Croq or any other service, you must configure the parameters `llm_api_url`, `llm_api_key`, and `llm_model`.

```r
fd_server("./fd_dir", 
    llm_api_url = "https://api.groq.com/openai/v1/chat/completions",
    llm_api_key = "gsk_use_your_own_key_here"), 
    llm_model = "llama-3.3-70b-versatile",
)
```

### Set default service

You can configure the default LLM service in `.Rprofile` using the following code.

```r
options(
  llm_api_key = "gsk-use_your_own_key_here",
  llm_api_url = "https://api.groq.com/openai/v1/chat/completions",
  llm_model = "llama-3.3-70b-versatile",
  llm_temperature = "0.5",
  llm_max_tokens = 1000
)
```

## Contribution

This package is being developed. Feel free to contribute to the package by sending pull requests or creating issues.

## License

MIT
