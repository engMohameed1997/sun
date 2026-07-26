package utils

import (
	"strconv"

	"github.com/gin-gonic/gin"
)

type PaginationParams struct {
	Page    int `json:"page"`
	PerPage int `json:"per_page"`
	Offset  int `json:"offset"`
}

func ParsePagination(c *gin.Context) PaginationParams {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	perPage, _ := strconv.Atoi(c.DefaultQuery("per_page", "20"))

	page = ClampInt(page, 1, 1000)
	perPage = ClampInt(perPage, 1, 100)

	offset := (page - 1) * perPage

	return PaginationParams{
		Page:    page,
		PerPage: perPage,
		Offset:  offset,
	}
}

func CalculateTotalPages(totalRecords, perPage int) int {
	if perPage <= 0 {
		return 1
	}
	pages := totalRecords / perPage
	if totalRecords%perPage != 0 {
		pages++
	}
	if pages == 0 {
		return 1
	}
	return pages
}
