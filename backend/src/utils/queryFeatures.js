const { Op } = require('sequelize');

const MAX_PER_PAGE = 1000;

/**
 * Parses query parameters for pagination, sorting, and filtering.
 *
 * @param {object} query - The request query object (req.query).
 * @param {object} config - Configuration object.
 * @param {Array<string>} config.allowedFilters - Array of field names that can be filtered.
 * @param {Array<string>} config.allowedSorts - Array of field names that can be sorted.
 * @param {Array<string>} config.searchableFields - Array of fields for the generic 'search' parameter.
 * @param {object} config.defaultWhere - Default WHERE conditions to apply.
 * @returns {object} An object containing sequelize options (limit, offset, order, where) and pagination metadata.
 */
const getQueryOptions = (query, config = {}) => {
  const { allowedFilters = [], allowedSorts = [], searchableFields = [], defaultWhere = {} } = config;

  const page = parseInt(query.page, 10) || 1;
  let per_page = parseInt(query.per_page, 10) || 20;
  if (per_page > MAX_PER_PAGE) {
    per_page = MAX_PER_PAGE;
  }
  const offset = (page - 1) * per_page;

  const options = {
    limit: per_page,
    offset: offset,
    where: { ...defaultWhere },
  };

  // Sorting
  const sort = query.sort || 'createdAt';
  const order = query.order && query.order.toLowerCase() === 'asc' ? 'ASC' : 'DESC';
  if (allowedSorts.includes(sort)) {
    options.order = [[sort, order]];
  } else {
    options.order = [['createdAt', 'DESC']]; // Default sort
  }

  // Filtering
  for (const key in query) {
    if (allowedFilters.includes(key) && query[key]) {
      if (key.endsWith('_desde')) { // Greater than or equal to (for dates)
        const field = key.replace('_desde', '');
        options.where[field] = { ...options.where[field], [Op.gte]: query[key] };
      } else if (key.endsWith('_hasta')) { // Less than or equal to (for dates)
        const field = key.replace('_hasta', '');
        options.where[field] = { ...options.where[field], [Op.lte]: query[key] };
      } else { // Exact match for other allowed filters
        options.where[key] = query[key];
      }
    }
  }

  // Generic Search
  if (query.search && searchableFields.length > 0) {
    options.where[Op.or] = searchableFields.map(field => ({
      [field]: { [Op.like]: `%${query.search}%` }
    }));
  }

  return { page, per_page, options };
};

/**
 * Adds pagination metadata to the response.
 *
 * @param {object} data - The data object from the Sequelize findAndCountAll result.
 * @param {number} page - Current page number.
 * @param {number} per_page - Items per page.
 * @returns {object} An object containing the data and meta for the response.
 */
const buildPaginatedResponse = (data, page, per_page) => {
  const total = data.count;
  const total_pages = Math.ceil(total / per_page);

  return {
    data: data.rows,
    meta: {
      page,
      per_page,
      total,
      total_pages,
    },
  };
};

module.exports = {
  getQueryOptions,
  buildPaginatedResponse,
};
