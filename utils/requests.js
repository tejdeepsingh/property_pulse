const apiDomain = process.env.NEXT_PUBLIC_API_DOMAIN || '';

function getApiUrl(path) {
  if (typeof window !== 'undefined') {
    return `/api${path}`;
  }

  if (!apiDomain) {
    return null;
  }

  return `${apiDomain}${path}`;
}


// Fetch all properties
async function fetchProperties({ showFeatured = false } = {}) {
  try {
    const url = getApiUrl(`/properties${showFeatured ? '/featured' : ''}`);

    if (!url) {
      return showFeatured ? [] : { total: 0, properties: [] };
    }

    const res = await fetch(url, { cache: 'no-store' });

    if (!res.ok) {
      throw new Error('Failed to fetch data');
    }

    return res.json();
  } catch (error) {
    console.log(error);
    return showFeatured ? [] : { total: 0, properties: [] };
  }
}

// Fetch single property
async function fetchProperty(id) {
  try {
    const url = getApiUrl(`/properties/${id}`);

    if (!url) {
      return null;
    }

    const res = await fetch(url);

    if (!res.ok) {
      throw new Error('Failed to fetch data');
    }

    return res.json();
  } catch (error) {
    console.log(error);
    return null;
  }
}

export { fetchProperties, fetchProperty };
