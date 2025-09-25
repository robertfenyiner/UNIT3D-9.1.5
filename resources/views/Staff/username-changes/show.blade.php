@extends('layout.with-main')

@section('breadcrumbs')
    <li class="breadcrumbV2">
        <a href="{{ route('staff.dashboard.index') }}" class="breadcrumb__link">
            {{ __('staff.staff-dashboard') }}
        </a>
    </li>
    <li class="breadcrumbV2">
        <a href="{{ route('staff.username-changes.index') }}" class="breadcrumb__link">
            Solicitudes de cambio de nombre de usuario
        </a>
    </li>
    <li class="breadcrumb--active">Solicitud #{{ $usernameChange->id }}</li>
@endsection

@section('page', 'page__staff-username-change--show')

@section('main')
    <section class="panelV2">
        <h2 class="panel__heading">
            Solicitud de cambio de nombre de usuario #{{ $usernameChange->id }}
        </h2>
        <div class="panel__body">
            <form
                action="{{ route('staff.username-changes.update', ['id' => $usernameChange->id]) }}"
                method="POST"
                x-data="{ status: '{{ $usernameChange->status }}' }"
            >
                @csrf
                <div class="form__group">
                    <label class="form__label">Usuario:</label>
                    <span class="form__text">
                        <a href="{{ route('users.show', ['user' => $usernameChange->user]) }}">
                            {{ $usernameChange->user->username }}
                        </a>
                    </span>
                </div>
                <div class="form__group">
                    <label class="form__label">Nombre de usuario actual:</label>
                    <span class="form__text">{{ $usernameChange->old_username ?? $usernameChange->user->username }}</span>
                </div>
                <div class="form__group">
                    <label for="new_username" class="form__label">Nuevo nombre de usuario:</label>
                    <input
                        type="text"
                        id="new_username"
                        name="new_username"
                        class="form__text"
                        value="{{ $usernameChange->new_username }}"
                        {{ $usernameChange->status !== 'Pending' ? 'disabled' : '' }}
                    >
                    @error('new_username')
                        <span class="form__hint">{{ $message }}</span>
                    @enderror
                </div>
                <div class="form__group">
                    <label for="reason" class="form__label">Razón:</label>
                    <textarea
                        id="reason"
                        name="reason"
                        class="form__textarea"
                        {{ $usernameChange->status !== 'Pending' ? 'disabled' : '' }}
                    >{{ $usernameChange->reason }}</textarea>
                </div>
                <div class="form__group">
                    <label class="form__label">Fecha de solicitud:</label>
                    <span class="form__text">{{ $usernameChange->created_at }}</span>
                </div>
                <div class="form__group">
                    <label for="status" class="form__label">Estado:</label>
                    <select
                        id="status"
                        name="status"
                        class="form__select"
                        x-model="status"
                        {{ $usernameChange->status !== 'Pending' ? 'disabled' : '' }}
                    >
                        <option value="Pending" {{ $usernameChange->status === 'Pending' ? 'selected' : '' }}>Pendiente</option>
                        <option value="Approved" {{ $usernameChange->status === 'Approved' ? 'selected' : '' }}>Aprobar</option>
                        <option value="Rejected" {{ $usernameChange->status === 'Rejected' ? 'selected' : '' }}>Rechazar</option>
                    </select>
                </div>
                <div class="form__group" x-show="status === 'Rejected'">
                    <label for="rejection_reason" class="form__label">Razón de rechazo:</label>
                    <textarea
                        id="rejection_reason"
                        name="rejection_reason"
                        class="form__textarea"
                        {{ $usernameChange->status !== 'Pending' ? 'disabled' : '' }}
                    >{{ $usernameChange->rejection_reason }}</textarea>
                </div>
                <div class="form__group">
                    <label for="staff_id" class="form__label">Revisado por:</label>
                    <span class="form__text">
                        @if ($usernameChange->staff)
                            <a href="{{ route('users.show', ['user' => $usernameChange->staff]) }}">
                                {{ $usernameChange->staff->username }}
                            </a>
                        @else
                            Pendiente de revisión
                        @endif
                    </span>
                </div>
                <div class="form__group">
                    <label for="updated_at" class="form__label">Última actualización:</label>
                    <span class="form__text">{{ $usernameChange->updated_at }}</span>
                </div>
                @if ($usernameChange->status === 'Pending')
                    <div class="form__group">
                        <button type="submit" class="form__button form__button--filled">
                            Guardar cambios
                        </button>
                    </div>
                @endif
            </form>
        </div>
    </section>
@endsection
