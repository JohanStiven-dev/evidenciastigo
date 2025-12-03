const ROLES = {
  COMERCIAL: 'Comercial',
  PRODUCTOR: 'Productor',
  CLIENTE: 'Cliente',
};

const STATUS = {
  PLANIFICACION: 'Planificación',
  CONFIRMADA: 'Confirmada',
  EN_CURSO: 'En Curso',
  FINALIZADA: 'Finalizada',
};

const SUB_STATUS = {
  BORRADOR: 'Borrador',
  EN_REVISION: 'En Revisión',
  RECHAZADO: 'Rechazado',
  APROBACION_FINAL: 'Aprobación Final', // Nuevo sub-estado
  PROGRAMADA: 'Programada',
  EN_EJECUCION: 'En Ejecución',
  CARGANDO_EVIDENCIAS: 'Cargando Evidencias',
  COMPLETADO: 'Completado',
  CANCELADO: 'Cancelado',
};

module.exports = {
  ROLES,
  STATUS,
  SUB_STATUS,
};

