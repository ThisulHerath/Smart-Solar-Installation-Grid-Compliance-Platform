import { useEffect, useState } from 'react';

import { useInventoryCatalog } from '../hooks/useInventoryCatalog';
import { SearchBox } from '../components/SearchBox';

import { ValidatedForm } from '../components/ValidatedForm';

import { useAuth } from '../context/AuthContext';

import {
  InventoryItem,
  Quote,
  Supplier,
  inventoryRequest as request,
} from '../services/inventoryService';
import { InventoryDialog } from '../components/InventoryDialog';
import { EquipmentEstimate } from '../components/EquipmentEstimate';

import './InventoryPage.css';

type Draft = Partial<InventoryItem>;

const empty: Draft = {
  sku: '',
  name: '',
  category: 'PANEL',
  manufacturer: '',
  model: '',
  supplierId: null,
  capacityWatts: 500,
  quantityInStock: 0,
  reorderLevel: 5,
  unitPriceUsd: 1,
  active: true,
};

const money = (value: number) =>
  new Intl.NumberFormat('en-LK', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value);

export function InventoryPage() {
  const { user } = useAuth();

  const canWrite = user?.roles.some((role) =>
    ['ADMINISTRATOR', 'INVENTORY_OFFICER'].includes(role)
  );

  const [search, setSearch] = useState('');
  const [category, setCategory] = useState('');
  const [sort, setSort] = useState('name');
  const [low, setLow] = useState(false);
  const [page, setPage] = useState(1);

  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');

  const [draft, setDraft] = useState<Draft | null>(null);
  const [suppliers, setSuppliers] = useState<Supplier[]>([]);

  const [proposals, setProposals] = useState<
    { id: string; recommendedKw: number }[]
  >([]);
  const [proposal, setProposal] = useState('');
  const [quotes, setQuotes] = useState<Quote[]>([]);

  const [reservations, setReservations] = useState<
    {
      id: string;
      equipmentQuoteId: string;
      itemName: string;
      quantity: number;
      status: string;
      totalPriceLkr: number;
    }[]
  >([]);

  const [revision, setRevision] = useState(0);
  const [supplierOpen, setSupplierOpen] = useState(false);
  const [quotesLoading, setQuotesLoading] = useState(false);
  const [dialogError, setDialogError] = useState('');

  const query = new URLSearchParams({
    search,
    sort,
    page: String(page),
    pageSize: '10',
    lowStock: String(low),
    ...(category ? { category } : {}),
  }).toString();

  const {
    items,
    total,
    loading,
    error: catalogError,
  } = useInventoryCatalog(query, revision);

  useEffect(() => {
    Promise.all([
      request<Supplier[]>('/suppliers'),
      request<typeof proposals>('/proposals'),
      request<typeof reservations>('/reservations'),
    ])
      .then(([s, p, r]) => {
        setSuppliers(s);
        setProposals(p);
        setReservations(r);
      })
      .catch((e) => setError(e.message));
  }, [revision]);

  useEffect(() => {
    let cancelled = false;

    setQuotes([]);
    setQuotesLoading(Boolean(proposal));

    if (proposal) {
      request<Quote[]>(`/proposals/${proposal}/equipment`)
        .then((data) => {
          if (!cancelled) {
            setQuotes(data);
          }
        })
        .catch((e) => {
          if (!cancelled) {
            setError(e.message);
          }
        })
        .finally(() => {
          if (!cancelled) {
            setQuotesLoading(false);
          }
        });
    }

    return () => {
      cancelled = true;
    };
  }, [proposal, revision]);

  async function act(
    action: () => Promise<unknown>,
    message: string
  ) {
    setBusy(true);
    setError('');
    setDialogError('');
    setNotice('');

    try {
      await action();

      setNotice(message);
      setRevision((x) => x + 1);
    } catch (e) {
      if (draft || supplierOpen) {
        setDialogError((e as Error).message);
      } else {
        setError((e as Error).message);
      }
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className="inventory-page operations-page">
      {/* Header */}

      <header className="inventory-heading">
        <div>
          <p className="eyebrow">
            EQUIPMENT & PROCUREMENT
          </p>

          <h1>Inventory</h1>

          <p>
            Manage equipment, review pricing, and reserve
            stock for approved proposals.
          </p>
        </div>

        {canWrite && (
          <div className="inventory-header-actions">
            <button
              className="inventory-secondary"
              onClick={() => {
                setDialogError('');
                setSupplierOpen(true);
              }}
            >
              Add supplier
            </button>

            <button
              className="btn btn-primary"
              onClick={() => {
                setDialogError('');
                setDraft({ ...empty });
              }}
            >
              Add equipment
            </button>
          </div>
        )}
      </header>

      {/* Notifications */}

      {(error || catalogError) && (
        <div
          role="alert"
          className="inventory-error"
        >
          {error || catalogError}
        </div>
      )}

      {notice && (
        <p
          role="status"
          className="inventory-notice"
        >
          {notice}
        </p>
      )}

      {/* Equipment Catalog */}

      <section className="inventory-panel">
        <div className="inventory-section-heading">
          <div>
            <h2>Equipment catalog</h2>

            <p>
              Search your stock and keep track of equipment
              available for allocation.
            </p>
          </div>

          <span className="inventory-count">
            {total} matching items
          </span>
        </div>

        <div className="inventory-filters">
          <SearchBox
            scope="inventory"
            label="Search inventory"
            value={search}
            onChange={(value) => {
              setSearch(value);
              setPage(1);
            }}
            suggestions={items.flatMap((item) => [
              item.name,
              item.sku,
            ])}
            loading={loading}
          />

          <label>
            Equipment type

            <select
              aria-label="Category"
              value={category}
              onChange={(e) => {
                setCategory(e.target.value);
                setPage(1);
              }}
            >
              <option value="">All equipment</option>
              <option value="PANEL">
                Solar panels
              </option>
              <option value="INVERTER">
                Inverters
              </option>
            </select>
          </label>

          <label>
            Sort by

            <select
              aria-label="Sort inventory"
              value={sort}
              onChange={(e) => {
                setSort(e.target.value);
                setPage(1);
              }}
            >
              <option value="name">
                Equipment name · A–Z
              </option>

              <option value="sku">
                SKU · A–Z
              </option>

              <option value="stock">
                Available stock
              </option>

              <option value="price">
                Unit price · USD
              </option>
            </select>
          </label>

          <label className="inventory-stock-filter">
            <input
              type="checkbox"
              checked={low}
              onChange={(e) => {
                setLow(e.target.checked);
                setPage(1);
              }}
            />

            Low stock only
          </label>
        </div>

        {(search || category || low) && (
          <button
            className="inventory-text-button"
            onClick={() => {
              setSearch('');
              setCategory('');
              setLow(false);
              setPage(1);
            }}
          >
            Clear filters
          </button>
        )}

        {loading ? (
          <p role="status">
            Loading inventory…
          </p>
        ) : (
          <div className="inventory-table">
            <table>
              <thead>
                <tr>
                  <th>Equipment</th>
                  <th>Supplier</th>
                  <th>Stock</th>
                  <th>Reserved</th>
                  <th>Available</th>
                  <th>USD / unit</th>
                  <th>Status</th>

                  {canWrite && <th>Actions</th>}
                </tr>
              </thead>

              <tbody>
                {items.map((item) => (
                  <tr key={item.id}>
                    <td>
                      <strong>{item.name}</strong>

                      <small>
                        {item.sku} · {item.capacityWatts} W ·{' '}
                        {item.model}
                      </small>
                    </td>

                    <td>
                      {item.supplier?.name || '—'}
                    </td>

                    <td>
                      {item.quantityInStock}
                    </td>

                    <td>
                      {item.reservedQuantity}
                    </td>

                    <td>
                      {item.availableQuantity}

                      <small>
                        Reorder at {item.reorderLevel}
                      </small>
                    </td>

                    <td>
                      ${money(item.unitPriceUsd)}
                    </td>

                    <td>
                      {!item.active ? (
                        'Inactive'
                      ) : item.lowStock ? (
                        <span className="stock-low">
                          Low stock
                        </span>
                      ) : (
                        'Available'
                      )}
                    </td>

                    {canWrite && (
                      <td>
                        <button
                          disabled={busy}
                          className="inventory-secondary"
                          onClick={() => {
                            setDialogError('');
                            setDraft({ ...item });
                          }}
                        >
                          Edit
                        </button>{' '}

                        {item.active && (
                          <button
                            className="inventory-text-button"
                            disabled={busy}
                            onClick={() =>
                              act(
                                () =>
                                  request(
                                    `/${item.id}`,
                                    'DELETE'
                                  ),
                                'Equipment deactivated.'
                              )
                            }
                          >
                            Deactivate
                          </button>
                        )}
                      </td>
                    )}
                  </tr>
                ))}
              </tbody>
            </table>

            {items.length === 0 && (
              <p>
                No equipment matches your filters. Try a
                shorter name or SKU, or clear the filters.
              </p>
            )}
          </div>
        )}

        <div className="inventory-toolbar">
          <button
            disabled={page === 1}
            onClick={() => setPage(page - 1)}
          >
            Previous
          </button>

          <span>
            Page {page} · {total} items
          </span>

          <button
            disabled={page * 10 >= total}
            onClick={() => setPage(page + 1)}
          >
            Next
          </button>
        </div>
      </section>

      {/* Equipment Dialog */}

      {draft && canWrite && (
        <InventoryDialog
          title={
            draft.id
              ? 'Edit equipment'
              : 'Add equipment'
          }
          busy={busy}
          onClose={() => setDraft(null)}
        >
          {dialogError && (
            <p
              role="alert"
              className="inventory-error"
            >
              {dialogError}
            </p>
          )}

          <ValidatedForm
            className="inventory-form"
            onSubmit={(e) => {
              e.preventDefault();

              act(
                async () => {
                  await request(
                    draft.id
                      ? `/${draft.id}`
                      : '',
                    draft.id ? 'PUT' : 'POST',
                    draft
                  );

                  setDraft(null);
                },
                'Equipment saved.'
              );
            }}
          >
            {(
              [
                'sku',
                'name',
                'manufacturer',
                'model',
              ] as const
            ).map((key) => (
              <label key={key}>
                {
                  {
                    sku: 'SKU',
                    name: 'Equipment name',
                    manufacturer: 'Manufacturer',
                    model: 'Model',
                  }[key]
                }

                <input
                  required={
                    key === 'sku' ||
                    key === 'name'
                  }
                  maxLength={
                    key === 'sku' ? 80 : 200
                  }
                  value={draft[key] || ''}
                  onChange={(e) =>
                    setDraft({
                      ...draft,
                      [key]: e.target.value,
                    })
                  }
                />
              </label>
            ))}

            <label>
              Category

              <select
                value={draft.category}
                onChange={(e) =>
                  setDraft({
                    ...draft,
                    category:
                      e.target.value as InventoryItem['category'],
                  })
                }
              >
                <option value="PANEL">
                  Solar panel
                </option>

                <option value="INVERTER">
                  Inverter
                </option>
              </select>
            </label>

            <label>
              Supplier

              <select
                value={draft.supplierId || ''}
                onChange={(e) =>
                  setDraft({
                    ...draft,
                    supplierId:
                      e.target.value || null,
                  })
                }
              >
                <option value="">
                  No supplier
                </option>

                {suppliers.map((s) => (
                  <option
                    key={s.id}
                    value={s.id}
                  >
                    {s.name}
                  </option>
                ))}
              </select>
            </label>

            {(
              [
                [
                  'capacityWatts',
                  'Capacity (watts)',
                ],
                [
                  'quantityInStock',
                  'Stock quantity',
                ],
                [
                  'reorderLevel',
                  'Reorder level',
                ],
                [
                  'unitPriceUsd',
                  'Unit price (USD)',
                ],
              ] as const
            ).map(([key, label]) => (
              <label key={key}>
                {label}

                <input
                  type="number"
                  required
                  min={
                    key === 'unitPriceUsd' ||
                    key === 'capacityWatts'
                      ? 0.01
                      : 0
                  }
                  max={1000000}
                  step={
                    key === 'unitPriceUsd' ||
                    key === 'capacityWatts'
                      ? '0.01'
                      : '1'
                  }
                  value={draft[key]}
                  onChange={(e) =>
                    setDraft({
                      ...draft,
                      [key]: Number(
                        e.target.value
                      ),
                    })
                  }
                />
              </label>
            ))}

            <label className="inventory-checkbox">
              <input
                type="checkbox"
                checked={draft.active}
                onChange={(e) =>
                  setDraft({
                    ...draft,
                    active: e.target.checked,
                  })
                }
              />

              Available for new quotes
            </label>

            <div className="inventory-dialog-actions">
              <button
                disabled={busy}
                type="submit"
              >
                Save equipment
              </button>

              <button
                className="inventory-secondary"
                disabled={busy}
                type="button"
                onClick={() => setDraft(null)}
              >
                Cancel
              </button>
            </div>
          </ValidatedForm>
        </InventoryDialog>
      )}

      {/* Supplier Dialog */}

      {supplierOpen && canWrite && (
        <InventoryDialog
          title="Add supplier"
          busy={busy}
          onClose={() => setSupplierOpen(false)}
        >
          {dialogError && (
            <p
              role="alert"
              className="inventory-error"
            >
              {dialogError}
            </p>
          )}

          <ValidatedForm
            className="inventory-form"
            onSubmit={(e) => {
              e.preventDefault();

              const form = e.currentTarget;
              const data = new FormData(form);

              act(
                async () => {
                  await request(
                    '/suppliers',
                    'POST',
                    {
                      name: data.get('name'),
                      contactEmail:
                        data.get('email') || null,
                      phone:
                        data.get('phone') || null,
                    }
                  );

                  form.reset();
                  setSupplierOpen(false);
                },
                'Supplier added.'
              );
            }}
          >
            <label>
              Name
              <input
                name="name"
                required
                maxLength={200}
              />
            </label>

            <label>
              Email
              <input
                name="email"
                type="email"
              />
            </label>

            <label>
              Phone
              <input
                name="phone"
                maxLength={50}
              />
            </label>

            <div className="inventory-dialog-actions">
              <button disabled={busy}>
                Save supplier
              </button>

              <button
                type="button"
                className="inventory-secondary"
                disabled={busy}
                onClick={() =>
                  setSupplierOpen(false)
                }
              >
                Cancel
              </button>
            </div>
          </ValidatedForm>
        </InventoryDialog>
      )}

      {/* Proposal Equipment & Pricing */}

      <section className="inventory-panel">
        <div className="inventory-section-heading">
          <div>
            <p className="eyebrow">
              PLAN · PRICE · RESERVE
            </p>

            <h2>
              Proposal equipment & pricing
            </h2>

            <p>
              Choose an approved solar proposal to
              prepare an itemized equipment estimate.
            </p>
          </div>
        </div>

        <div className="inventory-quote-selector">
          <label>
            Approved solar proposal

            <select
              aria-label="Approved proposal"
              value={proposal}
              onChange={(e) =>
                setProposal(e.target.value)
              }
            >
              <option value="">
                Select approved proposal
              </option>

              {proposals.map((p) => (
                <option
                  key={p.id}
                  value={p.id}
                >
                  {p.id.slice(0, 8)} ·{' '}
                  {p.recommendedKw} kW
                </option>
              ))}
            </select>
          </label>

          {canWrite && (
            <button
              disabled={
                !proposal ||
                busy ||
                quotesLoading
              }
              onClick={() =>
                act(
                  () =>
                    request(
                      `/proposals/${proposal}/price`,
                      'POST'
                    ),
                  'Pricing workflow finished. Review the result below.'
                )
              }
            >
              Calculate equipment price
            </button>
          )}
        </div>

        {quotesLoading ? (
          <p role="status">
            Loading equipment estimates…
          </p>
        ) : !proposal ? (
          <div className="inventory-empty">
            Select an approved proposal to view its
            estimates and reservation status.
          </div>
        ) : quotes.length === 0 ? (
          <div className="inventory-empty">
            No estimate yet. Calculate an equipment
            price to review the itemized costs.
          </div>
        ) : (
          quotes.map((quote) => (
            <EquipmentEstimate
              key={quote.id}
              quote={quote}
              canWrite={Boolean(canWrite)}
              busy={busy}
              onReserve={() =>
                act(
                  () =>
                    request(
                      '/reserve',
                      'POST',
                      { quoteId: quote.id }
                    ),
                  'Equipment reserved.'
                )
              }
              onRelease={() =>
                act(
                  () =>
                    request(
                      `/${quote.id}/release`,
                      'POST'
                    ),
                  'Reservation released.'
                )
              }
            />
          ))
        )}

        <div className="inventory-pricing-footnote">
          <span>
            Estimates use 500 W panels and an inverter
            suited to the approved system capacity.
          </span>

          <a
            href="https://www.exchangerate-api.com"
            target="_blank"
            rel="noreferrer"
          >
            Rates By Exchange Rate API
          </a>
        </div>
      </section>

      {/* Reservations */}

      <section className="inventory-panel">
        <h2>Reservations</h2>

        {reservations.length === 0 ? (
          <p>No reservations yet.</p>
        ) : (
          <div className="inventory-table">
            <table>
              <thead>
                <tr>
                  <th>Equipment</th>
                  <th>Quantity</th>
                  <th>Status</th>
                  <th>Equipment cost</th>
                </tr>
              </thead>

              <tbody>
                {reservations.map((r) => (
                  <tr key={r.id}>
                    <td>{r.itemName}</td>
                    <td>{r.quantity}</td>
                    <td>{r.status}</td>
                    <td>
                      LKR {money(r.totalPriceLkr)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </main>
  );
};
